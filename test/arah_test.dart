import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/router/arah.dart';
import 'package:pramu_apps/core/session/session_controller.dart';

const _id = '01a18f68-e55e-7251-9aac-4d5dcf4e68dd';

Akun _akun({String? langkah, List<String> peran = const ['MAJIKAN']}) =>
    Akun(id: _id, peran: peran, langkahBerikutnya: langkah);

void main() {
  test('sesi dimuat atau gagal dimuat menahan di /memuat', () {
    expect(arahkan(const AsyncLoading(), '/beranda'), '/memuat');
    expect(
      arahkan(AsyncError(Exception('x'), StackTrace.empty), '/beranda'),
      '/memuat',
    );
    expect(arahkan(const AsyncLoading(), '/memuat'), isNull);
  });

  test('belum masuk selalu ke /masuk', () {
    expect(arahkan(const AsyncData(null), '/beranda'), '/masuk');
    expect(arahkan(const AsyncData(null), '/booking/$_id'), '/masuk');
    expect(arahkan(const AsyncData(null), '/masuk'), isNull);
  });

  test('langkah onboarding dari server menentukan layar', () {
    expect(
      arahkan(AsyncData(_akun(langkah: 'PERSETUJUAN')), '/beranda'),
      '/persetujuan',
    );
    expect(
      arahkan(AsyncData(_akun(langkah: 'PERAN')), '/persetujuan'),
      '/peran',
    );
    expect(arahkan(AsyncData(_akun(langkah: 'KTP')), '/job'), '/lanjutkan');
    expect(arahkan(AsyncData(_akun(langkah: 'KTP')), '/lanjutkan'), isNull);
  });

  test('onboarding selesai: layar pra-masuk diarahkan ke Beranda, layar lain dibiarkan', () {
    final selesai = AsyncData<Akun?>(_akun());
    for (final r in rutePraMasuk) {
      expect(arahkan(selesai, r), '/beranda', reason: r);
    }
    expect(arahkan(selesai, '/'), '/beranda');
    expect(arahkan(selesai, '/booking/$_id'), isNull);
    expect(arahkan(selesai, '/job/buat'), isNull);
  });

  test('deep link dengan id bukan UUID ditolak (Docs/19 M5)', () {
    final selesai = AsyncData<Akun?>(_akun());
    expect(arahkan(selesai, '/booking/..'), '/beranda');
    expect(arahkan(selesai, '/penugasan/1'), '/beranda');
    expect(arahkan(selesai, '/percakapan/${_id.toUpperCase()}'), '/beranda');
  });
}
