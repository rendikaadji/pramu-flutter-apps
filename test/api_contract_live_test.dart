// Uji kontrak terhadap backend pramu-laravel-web yang benar-benar jalan (bukan mock).
// Dilewati secara default. Dijalankan job CI `contract`, atau lokal setelah backend jalan:
//   flutter test test/api_contract_live_test.dart \
//     --dart-define=LIVE_API=true --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
// Kasus kontrak per endpoint ditambahkan bersama modulnya (Docs/18 §1, Docs/15 §3.3).
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/booking/booking.dart';
import 'package:pramu_apps/features/job/job.dart';
import 'package:pramu_apps/features/penugasan/penugasan.dart';

import 'helpers/memory_token_store.dart';

const _live = bool.fromEnvironment('LIVE_API');

void main() {
  test('galat API memakai amplop {error: {code, message, fields}} dengan kode PRD §24', () async {
    final api = ApiClient(
      tokens: MemoryTokenStore(),
      deviceId: 'contract',
      onUnauthorized: () {},
    );
    await expectLater(
      api.get('/tidak-ada'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 404)
            .having((e) => e.code, 'code', 'NOT_FOUND'),
      ),
    );
  }, skip: _live ? false : 'butuh backend: --dart-define=LIVE_API=true');

  test(
    'alur masuk, persetujuan, peran, dan daftar terbaca oleh model aplikasi',
    () async {
      final tokens = MemoryTokenStore();
      final api = ApiClient(
        tokens: tokens,
        deviceId: 'contract',
        onUnauthorized: () {},
      );
      // Nomor unik per jalan agar akun selalu baru (OTP tetap 123456 di backend CI).
      final telepon = '0812${DateTime.now().millisecondsSinceEpoch % 100000000}'
          .padRight(12, '0');

      await api.post('/auth/otp', data: {'telepon': telepon});
      final masuk = await api.post(
        '/auth/otp/verifikasi',
        data: {
          'telepon': telepon,
          'kode': '123456',
          'nama_perangkat': 'Kontrak',
        },
      ) as Json;
      await tokens.write(masuk['token'] as String);
      expect(
        Akun.fromJson(masuk['akun'] as Json).langkahBerikutnya,
        'PERSETUJUAN',
      );

      final dokumen = (await api.get('/persetujuan/terbaru') as List)
          .cast<Json>();
      await api.post(
        '/persetujuan',
        data: {
          'persetujuan': [
            for (final d in dokumen) {'jenis': d['jenis'], 'versi': d['versi']},
          ],
        },
        options: ApiClient.idempotent(newIdempotencyKey()),
      );
      final akun = Akun.fromJson(
        await api.post(
          '/me/peran',
          data: {'peran': 'MAJIKAN'},
          options: ApiClient.idempotent(newIdempotencyKey()),
        ) as Json,
      );
      expect(akun.peran, contains('MAJIKAN'));
      expect(akun.langkahPerPeran.keys, ['MAJIKAN']);
      expect(akun.langkahBerikutnya, isNot(anyOf('PERSETUJUAN', 'PERAN')));

      final beranda =
          await api.get('/beranda', query: {'peran': 'MAJIKAN'}) as Json;
      expect(
        beranda.keys,
        containsAll(['kartu_tindakan', 'penugasan_berjalan', 'job_saya']),
      );

      final kategori = [
        for (final k in await api.get('/kategori') as List)
          Kategori.fromJson(k as Json),
      ];
      expect(kategori.map((k) => k.tipe).toSet(), {'PERIODIK', 'INSIDENTAL'});

      final booking = await api.getPage(
        '/booking',
        Booking.fromJson,
        query: {'peran': 'MAJIKAN'},
      );
      expect(booking.items, isEmpty);
      final penugasan = await api.getPage(
        '/penugasan',
        Penugasan.fromJson,
        query: {'peran': 'MAJIKAN'},
      );
      expect(penugasan.items, isEmpty);
      final notifikasi = await api.getPage('/notifikasi', (j) => j);
      expect(notifikasi.extra, contains('belum_dibaca'));
      final jobSaya = await api.getPage('/me/job', Job.fromJson);
      expect(jobSaya.hasMore, isFalse);
    },
    skip: _live ? false : 'butuh backend: --dart-define=LIVE_API=true',
  );
}
