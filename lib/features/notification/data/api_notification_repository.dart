import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';
import 'package:pramu_apps/features/notification/domain/notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._api);
  final ApiClient _api;

  @override
  Future<Paged<AppNotification>> list({String? cursor}) => _api.getPage(
    '/notifications',
    AppNotification.fromJson,
    query: {'cursor': ?cursor},
  );

  @override
  Future<int> unreadCount() async =>
      (await _api.get('/notifications/unread-count') as Map)['count'] as int;

  @override
  Future<void> markRead(String id) => _api.post('/notifications/$id/read');

  @override
  Future<void> markAllRead() => _api.post('/notifications/read-all');

  @override
  Future<void> registerPushToken(String token) =>
      _api.post('/me/devices', data: {'push_token': token});

  @override
  Future<void> unregisterPushToken(String token) =>
      _api.post('/me/devices/unregister', data: {'push_token': token});
}
