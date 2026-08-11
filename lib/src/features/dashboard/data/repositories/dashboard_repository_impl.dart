import 'package:intl/intl.dart';

import 'package:trudeals_realty_crm/src/core/network/network_client.dart';
import 'package:trudeals_realty_crm/src/core/network/network_typedefs.dart';
import 'package:trudeals_realty_crm/src/features/calendar/domain/entities/callback_event.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final NetworkClient _client;

  DashboardRepositoryImpl(this._client);

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  @override
  Future<NetworkResult<List<CallbackEvent>>> getSchedule({required DateTime from, required DateTime to}) {
    // `/api/calendar`'s `from`/`to` are date-only (OpenAPI: format "date")
    // and the server compares them against callback timestamps in UTC with
    // `to` as a literal midnight cutoff rather than an inclusive end-of-day
    // bound. Both quirks mean a plain same-day request can silently miss
    // callbacks later that day, or ones near local midnight that land on the
    // "other side" of the UTC boundary for this device's timezone. Padding
    // the request window a day on each side and then filtering the results
    // back down to the caller's actual local-day range fixes both: the
    // server always returns a superset, and the local-time filter below is
    // the ground truth for what's really in range.
    final localFrom = DateTime(from.year, from.month, from.day);
    final localToExclusive = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
    final paddedFrom = localFrom.subtract(const Duration(days: 1));
    final paddedTo = localToExclusive.add(const Duration(days: 1));

    return _client.get(
      path: '/api/calendar',
      queryParameters: {'from': _dateFmt.format(paddedFrom), 'to': _dateFmt.format(paddedTo)},
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        final callbacks = (json['callbacks'] as List? ?? const []);
        return callbacks
            .map((e) {
              final entry = Map<String, dynamic>.from(e as Map);
              final cb = Map<String, dynamic>.from(entry['callback'] as Map);
              return CallbackEvent(
                id: cb['id'].toString(),
                contactId: entry['contactId'].toString(),
                contactName: entry['contactName']?.toString() ?? '',
                scheduledAt: DateTime.parse(cb['when'] as String).toLocal(),
                note: cb['note'] as String?,
              );
            })
            .where((event) => !event.scheduledAt.isBefore(localFrom) && event.scheduledAt.isBefore(localToExclusive))
            .toList();
      },
    );
  }
}
