import '../../../../core/network/network_typedefs.dart';
import '../entities/notification.dart';

abstract interface class NotificationsRepository {
  Future<NetworkResult<List<AppNotification>>> getNotifications();
  Future<NetworkResult<void>> markAllRead();
}
