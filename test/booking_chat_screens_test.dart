import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/app.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/router/app_router.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/shared/app_ui/url_launch.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/memory_token_store.dart';

class AppEnv {
  AppEnv(this.container, this.backend, this.opened);
  final ProviderContainer container;
  final MockBackend backend;
  final List<Uri> opened;

  void go(String path) => container.read(routerProvider).go(path);
}

/// App penuh dengan mock backend tanpa latensi; peluncur URL diganti pencatat.
Future<AppEnv> boot(
  WidgetTester tester,
  String user, {
  bool launchOk = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tokens = MemoryTokenStore();
  final backend = MockBackend(tokens: tokens, latency: Duration.zero);
  await tokens.write(MockBackend.tokenFor(backend.userByName(user).id));
  final opened = <Uri>[];
  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      tokenStoreProvider.overrideWithValue(tokens),
      mockBackendProvider.overrideWithValue(backend),
      urlLauncherProvider.overrideWithValue((uri, mode) async {
        opened.add(uri);
        return launchOk;
      }),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PramuApp()),
  );
  await tester.pumpAndSettle();
  return AppEnv(container, backend, opened);
}

Future<void> tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
}

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

Finder dialogButton(String label) =>
    find.descendant(of: find.byType(Dialog), matching: find.text(label));

void main() {
  setUpAll(initLocale);

  Booking sitiBooking(MockBackend b) => b.booking(
    b.bookings.values
        .firstWhere(
          (x) => x.assistant.name == 'Siti' && x.seeker.name == 'Bu Rina',
        )
        .id,
  );

  group('chat M-60/M-61', () {
    testWidgets('daftar -> ruang -> kirim; kontak disamarkan apa adanya', (
      tester,
    ) async {
      final env = await boot(tester, 'Bu Rina');
      env.go('/s/chat');
      await settle(tester);
      expect(find.text('Siti'), findsWidgets);
      final conv = env.backend.conversations.values.firstWhere(
        (c) => c.seekerId == env.backend.userByName('Bu Rina').id,
      );
      await tester.tap(find.byKey(K.conversationTile(conv.id)).first);
      await settle(tester);

      await tester.enterText(
        find.byKey(K.chatInput),
        'Halo, hubungi 081234567890',
      );
      await tester.pump();
      expect(find.textContaining('akan disamarkan'), findsOneWidget);
      await tap(tester, find.byKey(K.chatSend));
      await settle(tester);
      expect(find.textContaining('[nomor disembunyikan]'), findsOneWidget);
      expect(find.text('Kontak disamarkan'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('081234567890'), findsNothing);
    });

    testWidgets('gagal kirim -> status gagal, ketuk untuk ulangi', (
      tester,
    ) async {
      final env = await boot(tester, 'Bu Rina');
      final conv = env.backend.conversations.values.firstWhere(
        (c) => c.seekerId == env.backend.userByName('Bu Rina').id,
      );
      env.go('/chat/${conv.id}');
      await settle(tester);
      await tester.enterText(find.byKey(K.chatInput), '/gagal');
      await tap(tester, find.byKey(K.chatSend));
      await settle(tester);
      expect(find.text('Gagal, ketuk untuk ulangi'), findsOneWidget);
    });

    testWidgets('daftar kosong -> keadaan kosong', (tester) async {
      final env = await boot(tester, 'Bu Maya');
      env.go('/s/chat');
      await settle(tester);
      expect(find.text('Belum ada percakapan'), findsOneWidget);
    });
  });

  group('booking M-72..M-77', () {
    testWidgets('detail kontrak: jadwal periode tanpa tagihan', (tester) async {
      final env = await boot(tester, 'Bu Rina');
      final b = sitiBooking(env.backend);
      env.go('/bookings/${b.id}');
      await settle(tester);
      expect(find.text('Jadwal periode'), findsOneWidget);
      expect(find.textContaining('Bayar'), findsNothing);
      expect(find.textContaining('dompet'), findsNothing);
    });

    testWidgets('batalkan: alasan -> konfirmasi -> kontrak dibatalkan', (
      tester,
    ) async {
      final env = await boot(tester, 'Bu Rina');
      final b = sitiBooking(env.backend);
      env.go('/bookings/${b.id}/cancel');
      await settle(tester);
      expect(find.textContaining('Perkiraan dana'), findsNothing);
      await tap(tester, find.byKey(K.cancelReason(0)));
      await tester.pump();
      await tap(tester, find.byKey(K.cancelSubmit));
      await settle(tester);
      await tester.tap(dialogButton('Batalkan kontrak'));
      await settle(tester);
      expect(env.backend.bookings[b.id]!.status, BookingStatus.cancelled);
    });

    testWidgets(
      'batalkan: 409 bila status sudah berubah -> dialog muat ulang',
      (tester) async {
        final env = await boot(tester, 'Bu Rina');
        final b = sitiBooking(env.backend);
        env.go('/bookings/${b.id}/cancel');
        await settle(tester);
        await tap(tester, find.byKey(K.cancelReason(0)));
        await tester.pump();
        env.backend.bookings[b.id] = env.backend.bookings[b.id]!.copyWith(
          status: BookingStatus.completed,
        );
        await tap(tester, find.byKey(K.cancelSubmit));
        await settle(tester);
        await tester.tap(dialogButton('Batalkan kontrak'));
        await settle(tester);
        expect(find.text('Data sudah berubah'), findsOneWidget);
      },
    );

    for (final who in ['Bu Rina', 'Siti']) {
      testWidgets('kontrak selesai: $who tetap bisa melaporkan', (
        tester,
      ) async {
        final env = await boot(tester, who);
        final b = sitiBooking(env.backend);
        env.backend.bookings[b.id] = env.backend.bookings[b.id]!.copyWith(
          status: BookingStatus.completed,
        );
        env.go('/bookings/${b.id}');
        await settle(tester);
        final f = find.byKey(K.bookingReport);
        await tester.scrollUntilVisible(
          f,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(f, findsOneWidget);
        await tap(tester, f);
        await settle(tester);
        expect(find.byKey(K.reportDescription), findsOneWidget);
      });
    }

    testWidgets('kesepakatan: setuju versi usang -> 409 muat ulang', (
      tester,
    ) async {
      final env = await boot(tester, 'Siti');
      final b = sitiBooking(env.backend);
      final app = env.backend.applications[b.applicationId]!;
      final a = env.backend.agreements.values.firstWhere(
        (x) => x.applicationId == app.id,
      );
      final fresh = a.copyWith(
        clearApprovals: true,
        seekerApprovedAt: DateTime.now().toUtc(),
        bookingId: null,
      );
      final id = ulid();
      env.backend.agreements[id] = Agreement(
        id: id,
        applicationId: app.id,
        version: 1,
        rate: fresh.rate,
        unit: fresh.unit,
        periodCount: fresh.periodCount,
        startDate: fresh.startDate,
        proposedBy: Role.seeker,
        seekerApprovedAt: fresh.seekerApprovedAt,
      );
      env.go('/agreements/$id');
      await settle(tester);
      expect(find.byKey(K.agreementApprove), findsOneWidget);
      // server menaikkan versi di belakang layar
      env.backend.agreements[id] = env.backend.agreements[id]!.copyWith(
        version: 2,
        rate: fresh.rate + 100000,
        clearApprovals: true,
      );
      await tap(tester, find.byKey(K.agreementApprove));
      await settle(tester);
      await tester.tap(dialogButton('Setujui'));
      await settle(tester);
      expect(find.text('Data sudah berubah'), findsOneWidget);
      await tester.tap(find.text('Muat ulang'));
      await settle(tester);
      expect(find.text('Versi 2'), findsOneWidget);
      expect(find.textContaining('Sebelumnya'), findsOneWidget);
    });
  });
}
