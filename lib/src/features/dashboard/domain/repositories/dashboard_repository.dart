import '../../../../core/network/network_typedefs.dart';
import '../entities/dashboard_stats.dart';
import '../../../calendar/domain/entities/callback_event.dart';

abstract interface class DashboardRepository {
  Future<NetworkResult<DashboardStats>> getStats();
  Future<NetworkResult<List<CallbackEvent>>> getTodaySchedule();
}
