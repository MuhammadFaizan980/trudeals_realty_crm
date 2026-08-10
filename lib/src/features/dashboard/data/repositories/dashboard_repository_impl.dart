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
    return _client.get(
      path: '/api/calendar',
      queryParameters: {'from': _dateFmt.format(from), 'to': _dateFmt.format(to)},
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        final callbacks = (json['callbacks'] as List? ?? const []);
        return callbacks.map((e) {
          final entry = Map<String, dynamic>.from(e as Map);
          final cb = Map<String, dynamic>.from(entry['callback'] as Map);
          return CallbackEvent(
            id: cb['id'].toString(),
            contactId: entry['contactId'].toString(),
            contactName: entry['contactName']?.toString() ?? '',
            scheduledAt: DateTime.parse(cb['when'] as String),
            note: cb['note'] as String?,
          );
        }).toList();
      },
    );
  }
}
