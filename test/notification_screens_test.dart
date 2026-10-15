import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';
import 'package:pramu_apps/features/notification/presentation/screens/notifications_screen.dart';

import 'helpers/rnr_harness.dart';

void main() {
  const ulid = '01ARZ3NDEKTSV4RRFFQ69G5FAV';

  AppNotification notif(
    Rig r,
    NotificationType type,
    String? target, {
    String title = 'Judul',
    int daysAgo = 0,
    Role? role,
  }) {
    final n = AppNotification(
      id: r.backend.newId(),
      type: type,
      title: title,
      body: 'Isi',
      createdAt: r.backend.now().subtract(Duration(days: daysAgo)),
      targetId: target,
      role: role,
    );
    (r.backend.notifications[r.meId] ??= []).add(n);
    return n;
  }

  testWidgets('M-23: dikelompokkan, tandai semua dibaca, kosong', (t) async {
    final r = await Rig.login('Bu Rina');
    notif(r, NotificationType.booking, ulid, title: 'Lama', daysAgo: 3);
    await t.pumpWidget(rig(r));
    await t.pumpAndSettle();
    expect(find.text('Hari ini'), findsOneWidget);
    expect(find.text('Sebelumnya'), findsOneWidget);
    expect(find.byKey(K.notificationMarkAll), findsOneWidget);

    await t.tap(find.byKey(K.notificationMarkAll));
    await t.pumpAndSettle();
    expect(find.byKey(K.notificationMarkAll), findsNothing);
    expect(r.backend.notifications[r.meId]!.every((n) => !n.unread), isTrue);

    final empty = await Rig.login('Dewi');
    await t.pumpWidget(rig(empty));
    await t.pumpAndSettle();
    expect(find.text('Belum ada notifikasi'), findsOneWidget);
  });

  testWidgets('M-23: tap -> dibaca + deep link ke rute allowlist', (t) async {
    final r = await Rig.login('Bu Rina');
    final app = r.backend.applications.values.first;
    final n = notif(r, NotificationType.application, app.id, title: 'Uji');
    await t.pumpWidget(rig(r));
    await t.pumpAndSettle();
    await t.tap(find.byKey(K.notificationTile(n.id)));
    await t.pumpAndSettle();
    expect(find.text('DETAIL_LAMARAN'), findsOneWidget);
    expect(
      r.backend.notifications[r.meId]!.firstWhere((x) => x.id == n.id).unread,
      isFalse,
    );
  });

  testWidgets('M-23: type/ID palsu tidak crash, tetap di layar aman', (
    t,
  ) async {
    final r = await Rig.login('Bu Rina');
    final bad = notif(r, NotificationType.application, '../../admin');
    final unknown = notif(r, NotificationType.from('hack'), ulid);
    await t.pumpWidget(rig(r));
    await t.pumpAndSettle();
    for (final n in [bad, unknown]) {
      await t.ensureVisible(find.byKey(K.notificationTile(n.id)));
      await t.tap(find.byKey(K.notificationTile(n.id)));
      await t.pumpAndSettle();
      expect(find.text('Notifikasi ini belum bisa dibuka.'), findsOneWidget);
      expect(find.text('DETAIL_LAMARAN'), findsNothing);
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('M-23: notifikasi peran lain -> ganti peran + snackbar', (
    t,
  ) async {
    final r = await Rig.login('Bu Maya');
    final u = r.backend.users[r.meId]!;
    final other = u.activeRole == Role.assistant ? Role.seeker : Role.assistant;
    final app = r.backend.applications.values.first;
    final n = notif(r, NotificationType.application, app.id, role: other);
    await t.pumpWidget(rig(r));
    await t.pumpAndSettle();
    await t.tap(find.byKey(K.notificationTile(n.id)));
    await t.pumpAndSettle();
    expect(find.text('Sekarang sebagai ${other.label}'), findsOneWidget);
    expect(r.backend.users[r.meId]!.activeRole, other);
  });

  testWidgets('M-23: error muat -> Coba lagi', (t) async {
    final r = await Rig.login('Bu Rina');
    await r.tokens.clear(); // 401
    await t.pumpWidget(rig(r));
    await t.pumpAndSettle();
    expect(find.text('Gagal memuat'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}

Widget rig(Rig r) => r.app(router: _router());

GoRouter _router() => GoRouter(
  initialLocation: Routes.notifications,
  routes: [
    GoRoute(
      path: Routes.notifications,
      builder: (_, _) => const NotificationsScreen(),
    ),
    GoRoute(
      path: Routes.applicationDetailT,
      builder: (_, _) => const Scaffold(body: Text('DETAIL_LAMARAN')),
    ),
  ],
);
