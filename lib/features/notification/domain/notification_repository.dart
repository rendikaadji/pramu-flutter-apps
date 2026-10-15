import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';

abstract interface class NotificationRepository {
  Future<Paged<AppNotification>> list({String? cursor});
  Future<int> unreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();

  /// Kirim token FCM saat login & `onTokenRefresh`; hapus saat logout.
  Future<void> registerPushToken(String token);
  Future<void> unregisterPushToken(String token);
}
