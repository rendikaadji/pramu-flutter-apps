import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/app.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/router/app_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/listing/data/listing_providers.dart';
import 'package:pramu_apps/features/listing/data/mock_listing_repository.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/domain/listing_repository.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/assistant_card.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/listing_card.dart';
import 'package:pramu_apps/shared/app_ui/url_launch.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/memory_token_store.dart';

/// Gagal jaringan pada `mine()` sebanyak [failures] kali, selebihnya mock biasa.
class FlakyListings extends MockListingRepository implements ListingRepository {
  FlakyListings(super.b, this.failures);
  int failures;

  /// Bila diisi, `pay()` menunggu gerbang ini (simulasi respons lambat).
  Completer<void>? payGate;

  @override
  Future<Invoice> pay(String id, {required String idempotencyKey}) async {
    await payGate?.future;
    return super.pay(id, idempotencyKey: idempotencyKey);
  }

  @override
  Future<List<Listing>> mine() {
    if (failures-- > 0) {
      throw ApiException(
        status: 0,
        code: 'NETWORK',
        message: 'Tidak dapat terhubung. Periksa sinyal lalu coba lagi.',
      );
    }
    return super.mine();
  }
}

class Env {
  Env(this.container, this.backend, this.opened, this.flaky);
  final FlakyListings flaky;
  final ProviderContainer container;
  final MockBackend backend;
  final List<Uri> opened;

  void go(String path) => container.read(routerProvider).go(path);
}

Future<Env> boot(WidgetTester tester, String user) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tokens = MemoryTokenStore();
  final backend = MockBackend(tokens: tokens, latency: Duration.zero);
  await tokens.write(MockBackend.tokenFor(backend.userByName(user).id));
  final opened = <Uri>[];
  final flaky = FlakyListings(backend, 0);
  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      tokenStoreProvider.overrideWithValue(tokens),
      mockBackendProvider.overrideWithValue(backend),
      urlLauncherProvider.overrideWithValue((uri, mode) async {
        opened.add(uri);
        return true;
      }),
      listingRepositoryProvider.overrideWithValue(flaky),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PramuApp()),
  );
  await tester.pumpAndSettle();
  return Env(container, backend, opened, flaky);
}

Finder field(Key k) =>
    find.descendant(of: find.byKey(k), matching: find.byType(TextField));

Future<void> tapKey(WidgetTester tester, Key k) async {
  final f = find.byKey(k);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> typeKey(WidgetTester tester, Key k, String text) async {
  final f = field(k);
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}

Future<void> pickDialogOk(WidgetTester tester) async {
  await tester.tap(find.byType(TextButton).last);
  await tester.pumpAndSettle();
}

Finder cardText(String t) =>
    find.descendant(of: find.byType(AssistantCard), matching: find.text(t));

void main() {
  setUpAll(initLocale);

  testWidgets('M-30 cari asisten: daftar, cari nama, hasil kosong + reset', (
    tester,
  ) async {
    final env = await boot(tester, 'Bu Rina');
    env.go(Routes.seekerSearch);
    await tester.pumpAndSettle();
    expect(cardText('Yuni'), findsOneWidget);

    await typeKey(tester, K.searchField, 'Lestari');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(cardText('Lestari'), findsOneWidget);
    expect(cardText('Yuni'), findsNothing);

    await typeKey(tester, K.searchField, 'zzzz');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum ada asisten yang cocok'), findsOneWidget);
    await tester.tap(find.text('Reset filter'));
    await tester.pumpAndSettle();
    expect(cardText('Yuni'), findsOneWidget);
  });

  testWidgets('M-35 error jaringan -> Coba lagi -> daftar muncul', (
    tester,
  ) async {
    final env = await boot(tester, 'Bu Rina');
    env.flaky.failures = 1;
    env.go(Routes.seekerJobs);
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat'), findsNothing);
    // Daftar lazy: kartu terakhir (urut createdAt sama) ada di bawah viewport.
    await tester.scrollUntilVisible(
      find.text('Pengasuh anak usia 3 tahun'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Pengasuh anak usia 3 tahun'), findsOneWidget);
  });

  testWidgets(
    'M-34 keluar layar saat pay() berjalan: tanpa error setelah dispose',
    (tester) async {
      final env = await boot(tester, 'Bu Rina');
      final l = env.backend.listings.values.firstWhere(
        (l) => l.status == ListingStatus.awaitingPayment,
      );
      env.flaky.payGate = Completer<void>();
      env.go(Routes.listingPay(l.id));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.listingPay));
      await tester.pump();
      env.go(Routes.seekerJobs); // layar bayar dibuang
      await tester.pumpAndSettle();
      env.flaky.payGate!.complete();
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('M-36 pelamar tampil, Tutup lowongan lewat dialog konfirmasi', (
    tester,
  ) async {
    final env = await boot(tester, 'Bu Rina');
    final l = env.backend.listings.values.firstWhere(
      (l) => l.title.startsWith('Pengasuh anak usia 3'),
    );
    env.go(Routes.listingManage(l.id));
    await tester.pumpAndSettle();
    expect(find.text('Yuni'), findsOneWidget);

    await tapKey(tester, K.listingClose);
    expect(find.text('Tutup lowongan?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Tutup lowongan'));
    await tester.pumpAndSettle();
    expect(find.text('Ditutup'), findsWidgets);
    expect(env.backend.listings[l.id]!.status, ListingStatus.closed);
  });

  testWidgets('M-33/M-34 wizard -> draf -> bayar -> status server open', (
    tester,
  ) async {
    final env = await boot(tester, 'Bu Rina');
    env.go(Routes.listingNew);
    await tester.pumpAndSettle();

    // langkah 1: validasi, lalu isi
    await tapKey(tester, K.wizardNext);
    expect(find.text('Pilih kategori'), findsOneWidget);
    await tapKey(tester, K.option('Pengasuh Anak'));
    await typeKey(tester, K.listingTitle, 'Pengasuh bayi akhir pekan');
    await tapKey(tester, K.wizardNext);

    // langkah 2
    await tapKey(tester, K.option('Bandung'));
    await tapKey(tester, K.wizardNext);

    // langkah 3
    await tapKey(tester, K.listingStartDate);
    await pickDialogOk(tester);
    await typeKey(tester, K.listingBudgetMin, '2000000');
    await typeKey(tester, K.listingBudgetMax, '1000000');
    await tapKey(tester, K.wizardNext);
    expect(
      find.text('Budget maksimum harus lebih besar dari minimum'),
      findsOneWidget,
    );
    await typeKey(tester, K.listingBudgetMax, '3000000');
    await tapKey(tester, K.wizardNext);

    // langkah 4 -> bayar
    expect(
      env.backend.listings.values.any(
        (l) =>
            l.title == 'Pengasuh bayi akhir pekan' &&
            l.status == ListingStatus.draft,
      ),
      isTrue,
    );
    await tapKey(tester, K.wizardNext);
    expect(find.text('Bayar biaya pasang'), findsOneWidget);

    await tapKey(tester, K.listingPay);
    expect(env.opened.single.host, 'checkout.xendit.co');
    expect(find.textContaining('Pembayaran sedang diproses'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 3));
    }
    await tester.pumpAndSettle();
    expect(find.text('Lowongan sudah tayang'), findsOneWidget);
  });

  testWidgets('M-33 keluar saat isian valid menawarkan simpan draf', (
    tester,
  ) async {
    final env = await boot(tester, 'Bu Rina');
    final me = env.backend.userByName('Bu Rina').id;
    final l = env.backend.listings.values.firstWhere(
      (l) => l.status == ListingStatus.draft && l.owner.id == me,
    );
    env.go('${Routes.listingNew}?draft=${l.id}');
    await tester.pumpAndSettle();
    expect(find.textContaining('Kategori dan judul'), findsOneWidget);
    await typeKey(tester, K.listingTitle, 'Judul baru');
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    expect(find.text('Simpan draf?'), findsOneWidget);
  });

  testWidgets('M-41/M-43/M-45 asisten melamar lalu menarik lamaran', (
    tester,
  ) async {
    final env = await boot(tester, 'Siti');
    final siti = env.backend.userByName('Siti').id;
    final l = env.backend.listings.values.firstWhere(
      (l) =>
          l.status == ListingStatus.open &&
          !l.requireSkck &&
          !l.skipInterview &&
          env.backend.applications.values.every(
            (a) => a.listingId != l.id || a.assistant.id != siti,
          ),
    );
    env.go(Routes.assistantListings);
    await tester.pumpAndSettle();
    expect(find.byType(ListingCard), findsWidgets);
    env.go(Routes.listingDetail(l.id));
    await tester.pumpAndSettle();
    await tapKey(tester, K.listingApply);

    await tapKey(tester, K.applySubmit);
    expect(find.text('Tulis pesan singkat untuk pencari'), findsOneWidget);
    await typeKey(tester, K.applyMessage, 'Saya siap mulai minggu depan.');
    for (var i = 0; i < l.screeningQuestions.length; i++) {
      await tester.enterText(find.byType(TextField).at(2 + i), 'Bersedia');
    }
    await tapKey(tester, K.applySubmit);
    expect(find.text('Lamaran terkirim'), findsOneWidget);
    // Regresi: setelah kembali, detail lowongan harus "Lihat lamaran" (bukan tetap "Lamar sekarang"):
    // provider turunan ikut di-invalidate saat melamar.
    GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(K.listingViewApplication), findsOneWidget);
    expect(find.byKey(K.listingApply), findsNothing);
    await tapKey(tester, K.listingViewApplication);
    await tester.pumpAndSettle();
    expect(find.text('Detail lamaran'), findsOneWidget);

    await tapKey(tester, K.applyWithdraw);
    await tester.tap(find.widgetWithText(TextButton, 'Tarik lamaran'));
    await tester.pumpAndSettle();
    expect(find.text('Ditarik'), findsWidgets);
  });

  testWidgets('M-42 SKCK terkunci -> CTA unggah SKCK', (tester) async {
    final env = await boot(tester, 'Bu Maya');
    await env.container
        .read(sessionProvider.notifier)
        .switchRole(Role.assistant);
    await tester.pumpAndSettle();
    final l = env.backend.listings.values.firstWhere(
      (l) => l.requireSkck && l.status == ListingStatus.open,
    );
    env.go(Routes.listingDetail(l.id));
    await tester.pumpAndSettle();
    expect(find.byKey(K.listingUploadSkck), findsOneWidget);
    expect(find.byKey(K.listingApply), findsNothing);
  });

  testWidgets('M-51/M-52 502 MEET_CREATE_FAILED -> Coba lagi -> Gabung', (
    tester,
  ) async {
    final env = await boot(tester, 'Siti');
    final old = env.backend.interviews.values.firstWhere(
      (i) => i.status == InterviewStatus.proposed,
    );
    final slot = DateTime.utc(2030, 1, 1, 3, 45);
    env.backend.interviews[old.id] = old.copyWith(slots: [slot]);
    env.go(Routes.interviewConfirm(old.id));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(RadioListTile<DateTime>).first);
    await tester.pumpAndSettle();
    await tapKey(tester, K.interviewConfirm);
    expect(
      find.textContaining('Tautan wawancara belum dapat dibuat'),
      findsOneWidget,
    );
    expect(env.backend.interviews[old.id]!.status, InterviewStatus.proposed);

    await tapKey(tester, K.retry);
    expect(find.text('Detail wawancara'), findsOneWidget);
    expect(find.text('Terjadwal'), findsWidgets);
    await tapKey(tester, K.interviewJoin);
    expect(env.opened.last.host, 'meet.google.com');
  });

  testWidgets('M-50/M-53 pencari ajukan slot lalu simpan catatan privat', (
    tester,
  ) async {
    final env = await boot(tester, 'Bu Rina');
    final app = env.backend.applications.values.firstWhere(
      (a) => a.assistant.name == 'Yuni',
    );
    env.go(Routes.interviewPropose(app.id));
    await tester.pumpAndSettle();

    await tapKey(tester, K.interviewSubmit);
    expect(find.text('Pilih minimal satu waktu wawancara.'), findsOneWidget);
    await tapKey(tester, K.interviewSlotAdd);
    await pickDialogOk(tester); // tanggal (besok)
    await pickDialogOk(tester); // jam
    expect(find.byKey(K.interviewSlot(0)), findsOneWidget);
    await tapKey(tester, K.interviewSubmit);
    expect(find.text('Detail wawancara'), findsOneWidget);

    final iv = env.backend.interviews.values.firstWhere(
      (i) => i.applicationId == app.id,
    );
    env.go(Routes.interviewEval(iv.id));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Hanya Anda yang dapat melihat'),
      findsOneWidget,
    );
    for (final a in ['communication', 'politeness', 'reliability']) {
      final stars = find.descendant(
        of: find.byKey(K.evalScore(a)),
        matching: find.byType(InkResponse),
      );
      await tester.tap(stars.at(3));
      await tester.pump();
    }
    await tapKey(tester, K.evalSubmit);
    expect(env.backend.evaluations[iv.id]!.communication, 4);
  });

  testWidgets('skala teks 1,3x tanpa overflow di layar utama fitur', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final env = await boot(tester, 'Bu Rina');
    final l = env.backend.listings.values.firstWhere(
      (l) => l.title.startsWith('Pengasuh anak usia 3'),
    );
    for (final p in [
      Routes.seekerSearch,
      Routes.seekerJobs,
      Routes.listingManage(l.id),
      Routes.listingPay(l.id),
      Routes.listingNew,
    ]) {
      env.go(p);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: p);
    }
  });
}
