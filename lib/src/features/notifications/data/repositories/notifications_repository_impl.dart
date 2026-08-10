import 'package:trudeals_realty_crm/src/core/network/network_client.dart';
import 'package:trudeals_realty_crm/src/core/network/network_typedefs.dart';
import 'package:trudeals_realty_crm/src/features/notifications/domain/entities/notification.dart';
import 'package:trudeals_realty_crm/src/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NetworkClient _client;

  NotificationsRepositoryImpl(this._client);

  @override
  Future<NetworkResult<List<AppNotification>>> getNotifications() {
    return _client.get(
      path: '/api/notifications',
      decoder: (data) {
        final json = Map<String, dynamic>.from(data as Map);
        return (json['notifications'] as List)
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
    );
  }

  @override
  Future<NetworkResult<void>> markAllRead() {
    return _client.post(path: '/api/notifications/read-all');
  }
}
