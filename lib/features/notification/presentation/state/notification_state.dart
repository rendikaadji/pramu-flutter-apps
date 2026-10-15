import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/notification/data/notification_providers.dart';
import 'package:pramu_apps/features/notification/data/push_providers.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';
import 'package:pramu_apps/features/notification/domain/push_service.dart';

class NotificationsState {
  const NotificationsState(this.items, this.nextCursor);
  final List<AppNotification> items;
  final String? nextCursor;

  bool get hasUnread => items.any((n) => n.unread);

  /// (Hari ini, Sebelumnya) menurut tanggal WIB; urutan asli dipertahankan.
  (List<AppNotification>, List<AppNotification>) grouped(DateTime now) {
    bool today(AppNotification n) => formatDate(n.createdAt) == formatDate(now);
    return (
      [
        for (final n in items)
          if (today(n)) n,
      ],
      [
        for (final n in items)
          if (!today(n)) n,
      ],
    );
  }
}

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  @override
  Future<NotificationsState> build() async {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    final p = await ref.read(notificationRepositoryProvider).list();
    return NotificationsState(p.items, p.nextCursor);
  }

  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || cur.nextCursor == null) return;
    final p = await ref
        .read(notificationRepositoryProvider)
        .list(cursor: cur.nextCursor);
    state = AsyncData(
      NotificationsState([...cur.items, ...p.items], p.nextCursor),
    );
  }

  void _patch(List<AppNotification> Function(List<AppNotification>) f) {
    final cur = state.value;
    if (cur == null) return;
    state = AsyncData(NotificationsState(f(cur.items), cur.nextCursor));
  }

  Future<void> markRead(String id) async {
    await ref.read(notificationRepositoryProvider).markRead(id);
    final at = DateTime.now().toUtc();
    _patch((l) => [for (final n in l) n.id == id ? n.markRead(at) : n]);
  }

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    final at = DateTime.now().toUtc();
    _patch((l) => [for (final n in l) n.markRead(at)]);
  }
}

final notificationsProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationsNotifier,
      NotificationsState
    >(NotificationsNotifier.new);

class PushPermissionNotifier extends AsyncNotifier<PushPermission> {
  @override
  Future<PushPermission> build() => ref.read(pushServiceProvider).permission();

  Future<void> request() async {
    final r = await ref.read(pushServiceProvider).requestPermission();
    state = AsyncData(r);
    await ref.read(pushTokenSyncProvider.notifier).sync();
  }
}

final pushPermissionProvider =
    AsyncNotifierProvider.autoDispose<PushPermissionNotifier, PushPermission>(
      PushPermissionNotifier.new,
    );
