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

  group('booking + payment M-72..M-77', () {
    testWidgets('alur sukses: detail -> bayar -> periksa -> diterima', (
      tester,
    ) async {
      final env = await boot(tester, 'Bu Rina');
      final b = sitiBooking(env.backend);
      env.go('/contracts');
      await settle(tester);
      await tap(tester, find.byKey(K.contractCard(b.id)));
      await settle(tester);
      expect(find.byKey(K.bookingPay), findsOneWidget);

      await tap(tester, find.byKey(K.bookingPay));
      await settle(tester);
      await tap(tester, find.byKey(K.payButton));
      await settle(tester);
      await tester.tap(dialogButton('Bayar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(env.opened.single.host, 'checkout.xendit.co');
      expect(find.byKey(K.paymentChecking), findsOneWidget);
      // polling server 5 dtk: cek ke-2 -> paid (webhook mock)
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(K.periodStatus), findsOneWidget);
      expect(find.text('Pembayaran diterima'), findsOneWidget);
    });

    testWidgets('halaman bayar tidak terbuka bila peluncur gagal', (
      tester,
    ) async {
      final env = await boot(tester, 'Bu Rina', launchOk: false);
      final b = sitiBooking(env.backend);
      final pid = b.periods.firstWhere((p) => p.status.canPay).id;
      env.go('/periods/$pid/pay');
      await settle(tester);
      await tap(tester, find.byKey(K.payButton));
      await settle(tester);
      await tester.tap(dialogButton('Bayar'));
      await settle(tester);
      expect(find.textContaining('belum bisa dibuka'), findsOneWidget);
      expect(find.byKey(K.payButton), findsOneWidget);
    });

    testWidgets('deep link /pay/return tidak pernah menandai lunas', (
      tester,
    ) async {
      final env = await boot(tester, 'Bu Rina');
      final pid = sitiBooking(env.backend).periods
          .firstWhere((p) => p.status.canPay)
          .id;
      env.go('/pay/return?period=$pid&status=PAID');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(K.paymentChecking), findsOneWidget);
      for (var i = 0; i < 26; i++) {
        await tester.pump(const Duration(seconds: 5));
      }
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(K.paymentPending), findsOneWidget);
      expect(find.text('Pembayaran diterima'), findsNothing);
      expect(
        find.textContaining('Anda tidak perlu membayar lagi'),
        findsOneWidget,
      );
    });

    testWidgets('konfirmasi selesai: dialog lalu dana dicairkan', (
      tester,
    ) async {
      final env = await boot(tester, 'Bu Rina');
      final b = sitiBooking(env.backend);
      final p = b.periods.firstWhere((p) => p.status.canPay);
      env.backend.periods[p.id] = p.copyWith(
        status: PeriodStatus.awaitingConfirmation,
        autoReleaseAt: DateTime.now().toUtc().add(const Duration(hours: 5)),
      );
      env.go('/periods/${p.id}/confirm');
      await settle(tester);
      expect(find.textContaining('otomatis dicairkan'), findsOneWidget);
      await tap(tester, find.byKey(K.confirmComplete));
      await settle(tester);
      await tester.tap(dialogButton('Konfirmasi selesai'));
      await settle(tester);
      expect(env.backend.periods[p.id]!.status.isFinal, isTrue);
    });

    testWidgets('batalkan: pratinjau server, 409 -> dialog muat ulang', (
      tester,
    ) async {
      final env = await boot(tester, 'Bu Rina');
      final b = sitiBooking(env.backend);
      env.go('/bookings/${b.id}/cancel');
      await settle(tester);
      expect(find.textContaining('Kembali ke Anda'), findsOneWidget);
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
    });

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
        fees: fresh.fees,
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

  group('wallet M-80..M-83', () {
    testWidgets('saldo tampil; tarik dana sukses; skala teks 1.3', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final env = await boot(tester, 'Siti');
      env.go('/a/wallet');
      await settle(tester);
      expect(find.byKey(K.walletBalance), findsOneWidget);
      expect(find.text('Rp1.350.000'), findsOneWidget);

      await tap(tester, find.byKey(K.walletPayoutOpen));
      await settle(tester);
      await tester.enterText(find.byKey(K.payoutAmount), '50000');
      await tap(tester, find.byKey(K.payoutSubmit));
      await settle(tester);
      expect(find.textContaining('BCA ••••7890'), findsWidgets);
      await tester.tap(dialogButton('Tarik dana'));
      await settle(tester);
      expect(find.byKey(K.payoutResult), findsOneWidget);
      expect(find.text('Antre'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nominal melebihi saldo -> pesan field, tanpa panggilan', (
      tester,
    ) async {
      final env = await boot(tester, 'Siti');
      env.go('/wallet/payout');
      await settle(tester);
      await tester.enterText(find.byKey(K.payoutAmount), '99999999');
      await tap(tester, find.byKey(K.payoutSubmit));
      await settle(tester);
      expect(
        find.text('Nominal melebihi saldo yang bisa ditarik.'),
        findsOneWidget,
      );
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('rekening: nomor tersamar setelah simpan', (tester) async {
      final env = await boot(tester, 'Siti');
      env.go('/wallet/bank');
      await settle(tester);
      expect(find.text('••••7890'), findsOneWidget);
      await tap(tester, find.byKey(K.bankEdit));
      await settle(tester);
      await tap(tester, find.byKey(K.bankSave));
      await settle(tester);
      expect(find.text('Pilih bank Anda.'), findsWidgets);
      expect(find.textContaining('8 sampai 16 digit'), findsOneWidget);
    });

    testWidgets('riwayat memuat transaksi', (tester) async {
      final env = await boot(tester, 'Siti');
      env.go('/wallet/history');
      await settle(tester);
      expect(find.textContaining('periode 1'), findsOneWidget);
    });
  });
}
