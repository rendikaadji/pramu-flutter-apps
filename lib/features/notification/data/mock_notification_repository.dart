import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';
import 'package:pramu_apps/features/notification/domain/notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(this._b);
  final MockBackend _b;

  List<AppNotification> get _mine => _b.notifications[_b.me.id] ??= [];

  @override
  Future<Paged<AppNotification>> list({String? cursor}) =>
      _b.run(() => _b.page(List.of(_mine), cursor));

  @override
  Future<int> unreadCount() =>
      _b.run(() => _mine.where((n) => n.unread).length);

  @override
  Future<void> markRead(String id) => _b.run(() {
    final l = _mine;
    final i = l.indexWhere((n) => n.id == id);
    if (i < 0) apiFail(404, 'NOT_FOUND', 'Notifikasi tidak ditemukan.');
    l[i] = l[i].markRead(_b.now());
  });

  @override
  Future<void> markAllRead() => _b.run(() {
    final l = _mine;
    for (var i = 0; i < l.length; i++) {
      l[i] = l[i].markRead(_b.now());
    }
  });

  @override
  Future<void> registerPushToken(String token) => _b.run(() {
    _b.me;
    _b.pushTokens.add(token);
  });

  @override
  Future<void> unregisterPushToken(String token) =>
      _b.run(() => _b.pushTokens.remove(token));
}
