import '../../../../core/network/network_typedefs.dart';
import '../../../calendar/domain/entities/callback_event.dart';

abstract interface class DashboardRepository {
  /// Callbacks + follow-ups scheduled within [from, to] (inclusive dates).
  Future<NetworkResult<List<CallbackEvent>>> getSchedule({required DateTime from, required DateTime to});
}
