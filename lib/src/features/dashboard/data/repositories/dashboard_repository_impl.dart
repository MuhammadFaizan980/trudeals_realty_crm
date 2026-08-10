import 'package:trudeals_realty_crm/src/core/network/network_client.dart';
import 'package:trudeals_realty_crm/src/core/network/network_typedefs.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:trudeals_realty_crm/src/features/calendar/domain/entities/callback_event.dart';
import 'package:trudeals_realty_crm/src/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final NetworkClient _client;

  DashboardRepositoryImpl(this._client);

  @override
  Future<NetworkResult<DashboardStats>> getStats() {
    return _client.get(
      path: '/api/dashboard/stats',
      decoder: (data) => _parseStats(data),
    );
  }

  @override
  Future<NetworkResult<List<CallbackEvent>>> getTodaySchedule() {
    return _client.get(
      path: '/api/dashboard/today',
      decoder: (data) => (data as List).map((e) => _parseCallback(e)).toList(),
    );
  }

  DashboardStats _parseStats(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    return DashboardStats(
      totalLeads: json['total_leads'] as int,
      newLeads: json['new_leads'] as int,
      activeDeals: json['active_deals'] as int,
      pipelineValue: (json['pipeline_value'] as num).toDouble(),
    );
  }

  CallbackEvent _parseCallback(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    return CallbackEvent(
      id: json['id'] as String,
      contactId: json['contact_id'] as String,
      contactName: json['contact_name'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      note: json['note'] as String?,
    );
  }
}
