import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';

import 'helpers/core_boot.dart';

void main() {
  setUpAll(initLocale);

  testWidgets('M-20: Langkah berikutnya dari data nyata + lowongan + kontrak', (
    t,
  ) async {
    await bootApp(t, user: 'Bu Rina');
    expect(find.byKey(K.homeNextStep), findsOneWidget);
    expect(find.textContaining('Tagihan periode'), findsOneWidget);
    expect(find.text('Lowongan aktif'), findsOneWidget);
    await t.scrollUntilVisible(
      find.text('Kontrak berjalan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kontrak berjalan'), findsOneWidget);
    expect(find.byKey(K.homeVerifyBanner), findsNothing);
  });

  testWidgets('M-20: pengguna baru -> ajakan buat lowongan pertama', (t) async {
    await bootApp(t, user: 'Bu Maya');
    expect(find.byKey(K.homeCreateListing), findsOneWidget);
    expect(find.text('Buat lowongan pertama'), findsOneWidget);
    expect(find.byKey(K.homeFindAssistant), findsOneWidget);
  });

  testWidgets('M-21: wawancara menunggu konfirmasi jadi langkah berikutnya', (
    t,
  ) async {
    await bootApp(t, user: 'Siti');
    expect(find.text('Konfirmasi jadwal wawancara'), findsOneWidget);
    expect(find.text('Lowongan untuk Anda'), findsOneWidget);
  });

  testWidgets('M-21: belum verifikasi -> banner + kartu kelengkapan profil', (
    t,
  ) async {
    await bootApp(t, user: 'Dewi');
    await tapKey(t, K.verificationLater);
    expect(find.byKey(K.homeVerifyBanner), findsOneWidget);
    expect(find.byKey(K.homeProfileMeter), findsOneWidget);
  });

  testWidgets('M-31: profil publik tanpa kontak, ada kontak tersamar + ajak', (
    t,
  ) async {
    final env = await bootApp(t, user: 'Bu Rina');
    final yuni = env.backend.userByName('Yuni');
    env.go('/assistants/${yuni.id}');
    await t.pumpAndSettle();
    expect(find.text('Yuni'), findsWidgets);
    await t.scrollUntilVisible(find.byKey(K.profileInvite), 200);
    expect(
      find.textContaining('disembunyikan sampai pembayaran'),
      findsOneWidget,
    );
    expect(find.textContaining('0813'), findsNothing);
    expect(find.textContaining('+62'), findsNothing);
    expect(find.byKey(K.profileInvite), findsOneWidget);
  });

  testWidgets('M-31: tidak ditemukan -> pesan + Coba lagi', (t) async {
    final env = await bootApp(t, user: 'Bu Rina');
    env.go('/assistants/${ulid()}');
    await t.pumpAndSettle();
    expect(find.text('Gagal memuat'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('M-40: validasi kota, simpan, meter kelengkapan naik', (t) async {
    final env = await bootApp(t, user: 'Bu Maya');
    env.backend.userByName('Bu Maya').activeRole = Role.assistant;
    await env.container.read(sessionProvider.notifier).refreshUser();
    await t.pumpAndSettle();
    env.go('/profile/edit');
    await t.pumpAndSettle();
    expect(find.text('Kelengkapan profil 0%'), findsOneWidget);

    await tapKey(t, K.profileSave);
    await t.fling(find.byType(ListView), const Offset(0, 3000), 3000);
    await t.pumpAndSettle();
    expect(find.text('Pilih minimal satu kategori'), findsOneWidget);
    expect(find.text('Kota wajib diisi'), findsOneWidget);

    await tapKey(t, K.profileCategory('Pengasuh Anak'));
    await typeInto(t, K.profileCity, 'Bandung');
    await typeInto(t, K.profileRate, '1500000');
    await t.fling(find.byType(ListView), const Offset(0, 3000), 3000);
    await t.pumpAndSettle();
    expect(find.textContaining('Kelengkapan profil 43%'), findsOneWidget);

    await tapKey(t, K.profileSave);
    final saved = env.backend.profiles[env.backend.userByName('Bu Maya').id];
    expect(saved?.city, 'Bandung');
    expect(saved?.rate, 1500000);
  });

  testWidgets('teks 130%: beranda dan edit profil tanpa overflow', (t) async {
    final env = await bootApp(t, user: 'Siti', textScale: 1.3);
    expect(t.takeException(), isNull);
    env.go('/profile/edit');
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
