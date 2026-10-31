import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/session/session_controller.dart';

/// Layar di luar kerangka utama yang dipakai sebelum onboarding selesai.
const rutePraMasuk = {
  '/memuat',
  '/masuk',
  '/persetujuan',
  '/peran',
  '/lanjutkan',
};

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);
final _rinci = RegExp(r'^/(job|booking|penugasan|percakapan)/([^/]+)$');

/// Ke mana pengguna diarahkan, atau null bila boleh tetap di [lokasi].
/// Murni (tanpa BuildContext) agar bisa diuji: sesi → layar masuk → langkah onboarding dari server → aplikasi.
String? arahkan(AsyncValue<Akun?> sesi, String lokasi) {
  // Deep link hanya untuk id berbentuk UUID (Docs/19 M5); selain itu kembali ke Beranda.
  final rinci = _rinci.firstMatch(lokasi);
  if (rinci != null && !_uuid.hasMatch(rinci[2]!) && lokasi != '/job/buat') {
    return '/beranda';
  }
  if (sesi.isLoading || sesi.hasError) {
    return lokasi == '/memuat' ? null : '/memuat';
  }
  final akun = sesi.value;
  if (akun == null) return lokasi == '/masuk' ? null : '/masuk';

  final tujuan = switch (akun.langkahBerikutnya) {
    null => null,
    'PERSETUJUAN' => '/persetujuan',
    'PERAN' => '/peran',
    _ => '/lanjutkan',
  };
  if (tujuan != null) return lokasi == tujuan ? null : tujuan;
  return rutePraMasuk.contains(lokasi) || lokasi == '/' ? '/beranda' : null;
}
