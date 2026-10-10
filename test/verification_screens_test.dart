import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/verification/data/photo_service.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';

import 'helpers/core_boot.dart';

Future<void> toReview(WidgetTester t, AppEnv env) async {
  await tapKey(t, K.verificationStart);
  await t.ensureVisible(find.text('Siap'));
  await t.tap(find.text('Siap'));
  await t.pumpAndSettle();
  await tapKey(t, K.ktpCapture);
  await tapKey(t, K.verificationNext);
  await tapKey(t, K.selfieCapture);
  await tapKey(t, K.verificationNext);
}

void main() {
  setUpAll(initLocale);

  testWidgets(
    'alur penuh: gerbang -> KTP -> selfie -> kirim -> terverifikasi',
    (t) async {
      final env = await bootApp(t, user: 'Dewi');
      await toReview(t, env);

      // kamera depan untuk selfie; tidak ada jalur galeri
      expect(env.photos.lastFront, isTrue);
      expect(env.photos.lastSource, PhotoSource.camera);

      // NIK salah ditolak lokal; Kirim butuh centang persetujuan
      await typeInto(t, K.nikInput, '123');
      await tapKey(t, K.verificationConsent);
      await tapKey(t, K.verificationSubmit);
      expect(find.text('Nomor KTP harus 16 digit'), findsOneWidget);

      await typeInto(t, K.nikInput, '3201234567890001');
      await tapKey(t, K.verificationSubmit);
      expect(find.byKey(K.verificationStatus), findsOneWidget);
      expect(find.text('Menunggu tinjauan'), findsOneWidget);
      // berkas lokal dihapus setelah unggah sukses
      expect(env.photos.deleted.toSet(), env.photos.created.toSet());

      // hasil review muncul pada pengecekan kedua
      await t.tap(find.text('Periksa status'));
      await t.pumpAndSettle();
      expect(find.text('Terverifikasi'), findsWidgets);
      expect(
        env.container.read(sessionProvider).user?.verification,
        VerificationStatus.verified,
      );
    },
  );

  testWidgets('ditolak: alasan tampil dan bisa unggah ulang', (t) async {
    final env = await bootApp(t, user: 'Dewi');
    await toReview(t, env);
    await typeInto(t, K.nikInput, '3201234567890000');
    await tapKey(t, K.verificationConsent);
    await tapKey(t, K.verificationSubmit);
    await t.tap(find.text('Periksa status'));
    await t.pumpAndSettle();
    expect(find.text('Verifikasi belum berhasil'), findsOneWidget);
    expect(find.textContaining('Foto KTP buram'), findsOneWidget);
    expect(find.text('Unggah ulang'), findsOneWidget);
  });

  testWidgets(
    'izin kamera ditolak: kartu + Buka Pengaturan; selfie tanpa galeri',
    (t) async {
      final env = await bootApp(t, user: 'Dewi');
      env.photos.failWith = const PhotoException(
        'Izin kamera dimatikan.',
        permissionDenied: true,
      );
      await tapKey(t, K.verificationStart);
      await t.tap(find.text('Siap'));
      await t.pumpAndSettle();
      await tapKey(t, K.ktpCapture);
      expect(find.text('Buka Pengaturan'), findsOneWidget);
      expect(find.text('Pilih dari galeri'), findsOneWidget);

      env.go('/verification/selfie');
      await t.pumpAndSettle();
      await tapKey(t, K.selfieCapture);
      expect(find.text('Buka Pengaturan'), findsOneWidget);
      expect(find.text('Pilih dari galeri'), findsNothing);
    },
  );

  testWidgets('meninggalkan alur menghapus foto sementara', (t) async {
    final env = await bootApp(t, user: 'Dewi');
    await tapKey(t, K.verificationStart);
    await t.tap(find.text('Siap'));
    await t.pumpAndSettle();
    await tapKey(t, K.ktpCapture);
    expect(env.photos.created, hasLength(1));
    env.go('/verification');
    await t.pumpAndSettle();
    expect(env.photos.deleted, contains(env.photos.created.first));
  });

  testWidgets('Nanti dulu -> beranda tanpa gerbang lagi', (t) async {
    await bootApp(t, user: 'Dewi');
    await tapKey(t, K.verificationLater);
    expect(find.byKey(K.roleSwitchChip), findsOneWidget);
  });

  testWidgets('SKCK: unggah dari galeri, berkas lokal dihapus', (t) async {
    final env = await bootApp(t, user: 'Dewi');
    env.go('/skck');
    await t.pumpAndSettle();
    await tapKey(t, K.verificationGallery);
    expect(env.photos.lastSource, PhotoSource.gallery);
    await tapKey(t, K.skckUpload);
    expect(find.text('Terverifikasi'), findsWidgets);
    expect(env.photos.deleted, contains(env.photos.created.first));
  });

  testWidgets('teks 130%: KTP dan tinjau tanpa overflow', (t) async {
    final env = await bootApp(t, user: 'Dewi', textScale: 1.3);
    await toReview(t, env);
    expect(find.byKey(K.nikInput), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
