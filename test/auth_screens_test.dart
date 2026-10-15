import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/verification/data/photo_service.dart';

import 'helpers/core_boot.dart';

void main() {
  setUpAll(initLocale);

  testWidgets('daftar -> OTP -> pilih peran -> beranda Pencari', (t) async {
    final env = await bootApp(t);
    await tapKey(t, K.welcomeRegister);

    // validasi lokal: field kosong
    await tapKey(t, K.registerSubmit);
    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(
      find.text('Centang persetujuan ini untuk melanjutkan'),
      findsOneWidget,
    );

    await typeInto(t, K.registerName, 'Budi Santoso');
    await typeInto(t, K.registerPhone, '081200001111');
    await typeInto(t, K.registerEmail, 'budi@example.com');
    await typeInto(t, K.registerPassword, 'Rahasia123');
    await tapKey(t, K.registerConsent);
    await tapKey(t, K.registerSubmit);

    // OTP salah -> pesan + tetap di layar
    expect(find.byKey(K.otpInput), findsOneWidget);
    await typeOtp(t, K.otpInput, '000000');
    await t.pumpAndSettle();
    expect(find.text('Kode OTP salah'), findsOneWidget);

    // OTP benar -> sesi + pilih peran
    await typeOtp(t, K.otpInput, kMockOtpOk);
    await t.pumpAndSettle();
    expect(find.byKey(K.roleContinue), findsOneWidget);
    await tapKey(t, K.roleSeeker);
    await tapKey(t, K.roleContinue);

    expect(find.byKey(K.verificationStart), findsOneWidget);
    final s = env.container.read(sessionProvider);
    expect(s.user?.activeRole, Role.seeker);
  });

  testWidgets('daftar: duplikat HP -> error di field (422)', (t) async {
    await bootApp(t);
    await tapKey(t, K.welcomeRegister);
    await typeInto(t, K.registerName, 'Rina Dua');
    await typeInto(t, K.registerPhone, '081234567890');
    await typeInto(t, K.registerEmail, 'rina2@example.com');
    await typeInto(t, K.registerPassword, 'Rahasia123');
    await tapKey(t, K.registerConsent);
    await tapKey(t, K.registerSubmit);
    expect(find.text('Nomor HP sudah terdaftar'), findsOneWidget);
    expect(find.byKey(K.otpInput), findsNothing);
  });

  testWidgets('OTP: 5 kali salah -> 429 terkunci dengan hitung mundur', (
    t,
  ) async {
    await bootApp(t);
    await tapKey(t, K.welcomeRegister);
    await typeInto(t, K.registerName, 'Budi Santoso');
    await typeInto(t, K.registerPhone, '081200001112');
    await typeInto(t, K.registerEmail, 'budi2@example.com');
    await typeInto(t, K.registerPassword, 'Rahasia123');
    await tapKey(t, K.registerConsent);
    await tapKey(t, K.registerSubmit);
    for (var i = 0; i < 5; i++) {
      await typeOtp(t, K.otpInput, '00000$i');
      await t.pumpAndSettle();
    }
    expect(find.textContaining('Terlalu banyak percobaan'), findsOneWidget);
    expect(find.textContaining('Coba lagi dalam'), findsOneWidget);
    // kirim ulang dinonaktifkan selama hitung mundur 5 menit berjalan
    final resend = t.widget<ButtonStyleButton>(
      find.descendant(
        of: find.byKey(K.otpResend),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(resend.onPressed, isNull);
  });

  testWidgets('masuk: salah -> pesan generik; benar -> beranda', (t) async {
    await bootApp(t);
    await tapKey(t, K.welcomeLogin);
    await typeInto(t, K.loginPhone, '081234567890');
    await typeInto(t, K.loginPassword, 'salahsekali');
    await tapKey(t, K.loginSubmit);
    expect(find.text('Nomor HP/email atau kata sandi salah.'), findsOneWidget);
    await typeInto(t, K.loginPassword, kMockPassword);
    await tapKey(t, K.loginSubmit);
    expect(find.byKey(K.notificationBell), findsOneWidget);
  });

  testWidgets('masuk: akun ditangguhkan -> kartu penjelas', (t) async {
    await bootApp(t);
    await tapKey(t, K.welcomeLogin);
    await typeInto(t, K.loginPhone, '08999999999');
    await typeInto(t, K.loginPassword, kMockPassword);
    await tapKey(t, K.loginSubmit);
    expect(find.text('Akun ditangguhkan'), findsOneWidget);
  });

  testWidgets(
    'lupa sandi: HP -> kode -> sandi baru -> masuk dengan sandi baru',
    (t) async {
      await bootApp(t);
      await tapKey(t, K.welcomeLogin);
      await tapKey(t, K.loginForgot);
      await typeInto(t, K.forgotIdentifier, '081234567890');
      await tapKey(t, K.forgotSend);
      await typeOtp(t, K.forgotCode, kMockOtpOk);
      await t.pumpAndSettle();
      await typeInto(t, K.forgotNewPassword, 'SandiBaru999');
      await tapKey(t, K.forgotSave);
      expect(find.byKey(K.loginSubmit), findsOneWidget);
      await typeInto(t, K.loginPhone, '081234567890');
      await typeInto(t, K.loginPassword, 'SandiBaru999');
      await tapKey(t, K.loginSubmit);
      expect(find.byKey(K.notificationBell), findsOneWidget);
    },
  );

  testWidgets('akun: tema tersimpan, ganti peran lewat sheet, keluar', (
    t,
  ) async {
    final env = await bootApp(t, user: 'Bu Maya');
    env.go('/account');
    await t.pumpAndSettle();
    await tapKey(t, K.accountRoleRow);
    expect(find.text('Gunakan Pramu sebagai'), findsOneWidget);
    await t.tap(find.text('Cari pekerjaan sebagai asisten'));
    await t.pumpAndSettle();
    expect(
      env.container.read(sessionProvider).user?.activeRole,
      Role.assistant,
    );

    env.go('/account');
    await t.pumpAndSettle();
    await tapKey(t, K.themeDark);
    expect(env.container.read(prefsProvider).getString('theme_mode'), 'dark');
    await t.pump(const Duration(seconds: 5)); // snackbar menutup tombol
    await t.pumpAndSettle();
    await tapKey(t, K.logout);
    await t.tap(find.text('Keluar').last);
    await t.pumpAndSettle();
    expect(find.byKey(K.welcomeLogin), findsOneWidget);
    expect(await env.container.read(tokenStoreProvider).read(), isNull);
  });

  for (final (who, path) in [
    ('Bu Rina', '/s/profile'),
    ('Siti', '/a/profile'),
  ]) {
    testWidgets('foto profil $who: unggah, file sementara dihapus, hapus', (
      t,
    ) async {
      final env = await bootApp(t, user: who);
      env.go(path);
      await t.pumpAndSettle();
      String? photo() => env.container.read(sessionProvider).user?.photoUrl;
      expect(photo(), isNull);

      await t.tap(find.byKey(const Key('profilePhoto')));
      await t.pumpAndSettle();
      await t.tap(find.text('Pilih dari galeri'));
      await t.pumpAndSettle();
      expect(photo(), isNotNull);
      expect(env.photos.lastSource, PhotoSource.gallery);
      expect(env.photos.deleted, env.photos.created);

      await t.pump(const Duration(seconds: 5));
      await t.tap(find.byKey(const Key('profilePhoto')));
      await t.pumpAndSettle();
      await t.tap(find.text('Hapus foto'));
      await t.pumpAndSettle();
      expect(photo(), isNull);
    });
  }

  testWidgets('perangkat: cabut perangkat ini = keluar', (t) async {
    final env = await bootApp(t, user: 'Bu Rina');
    env.go('/account/devices');
    await t.pumpAndSettle();
    expect(find.text('Perangkat ini'), findsWidgets);
    await t.tap(find.widgetWithText(FilledButton, 'Keluar').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Keluar').last);
    await t.pumpAndSettle();
    expect(find.byKey(K.welcomeLogin), findsOneWidget);
  });

  testWidgets('teks 130% di 360dp tanpa overflow (daftar)', (t) async {
    await bootApp(t, textScale: 1.3);
    await tapKey(t, K.welcomeRegister);
    expect(t.takeException(), isNull);
    await tapKey(t, K.registerSubmit);
    expect(t.takeException(), isNull);
  });
}
