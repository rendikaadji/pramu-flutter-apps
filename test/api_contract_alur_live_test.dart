// Uji kontrak dua pihak terhadap backend pramu-laravel-web yang benar-benar jalan: setiap respons dibaca model aplikasi,
// jadi perbedaan nama kolom, tipe, atau nilai null antara Laravel dan Flutter langsung gagal di sini.
// Dilewati secara default; dijalankan job CI `contract`, atau lokal:
//   flutter test test/api_contract_alur_live_test.dart \
//     --dart-define=LIVE_API=true --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
import 'dart:convert';
import 'dart:io' show zlib;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/akun/unggah.dart';
import 'package:pramu_apps/features/booking/booking.dart';
import 'package:pramu_apps/features/jelajah/jelajah_screen.dart';
import 'package:pramu_apps/features/job/job.dart';
import 'package:pramu_apps/features/penugasan/penugasan.dart';
import 'package:pramu_apps/features/profil/profil.dart';
import 'package:pramu_apps/features/tagihan/langganan.dart';
import 'package:pramu_apps/features/tagihan/tagihan.dart';

import 'helpers/memory_token_store.dart';

const _live = bool.fromEnvironment('LIVE_API');

/// PNG 1x1 berwarna [rgb]. Driver KTP tiruan menurunkan NIK dari isi foto KTP, jadi tiap akun butuh foto berbeda:
/// foto yang sama berarti NIK yang sama, dan akun kedua ditolak NIK_TIDAK_BISA_DIPAKAI (perilaku server yang benar).
Uint8List _png(int rgb) {
  int crc(List<int> data) {
    var c = 0xFFFFFFFF;
    for (final b in data) {
      c ^= b;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
      }
    }
    return c ^ 0xFFFFFFFF;
  }

  List<int> u32(int v) => [v >> 24 & 255, v >> 16 & 255, v >> 8 & 255, v & 255];
  List<int> potong(String jenis, List<int> isi) {
    final badan = [...ascii.encode(jenis), ...isi];
    return [...u32(isi.length), ...badan, ...u32(crc(badan))];
  }

  final piksel = zlib.encode([0, rgb >> 16 & 255, rgb >> 8 & 255, rgb & 255]);
  return Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    ...potong('IHDR', [...u32(1), ...u32(1), 8, 2, 0, 0, 0]),
    ...potong('IDAT', piksel),
    ...potong('IEND', []),
  ]);
}

/// MP4 minimal dengan kotak `mvhd` (durasi [detik]).
Uint8List _mp4(int detik) {
  final b = BytesBuilder();
  void n(int v) => b.add([v >> 24 & 255, v >> 16 & 255, v >> 8 & 255, v & 255]);
  b.add([0, 0, 0, 20]);
  b.add(ascii.encode('ftypisom'));
  n(512);
  b.add(ascii.encode('isom'));
  final mvhd = BytesBuilder()
    ..add(ascii.encode('mvhd'))
    ..add([0, 0, 0, 0]);
  final isi = mvhd.toBytes();
  final badan = BytesBuilder()..add(isi);
  for (final v in [0, 0, 1000, detik * 1000]) {
    badan.add([v >> 24 & 255, v >> 16 & 255, v >> 8 & 255, v & 255]);
  }
  badan.add(List.filled(80, 0));
  final kotak = badan.toBytes();
  n(kotak.length + 12);
  b.add(ascii.encode('moov'));
  n(kotak.length + 4);
  b.add(kotak);
  b.add(List.filled(64, 0));
  return b.toBytes();
}

/// Rumah contoh di Kebayoran Baru (wilayah pilot pada pencari wilayah tiruan backend).
const _rumah = {'lintang': -6.2433, 'bujur': 106.7997};

class _Pengguna {
  _Pengguna(this.api, this.akun);
  final ApiClient api;
  Akun akun;
}

Future<_Pengguna> _akunSiap(String peran, int urut) async {
  final tokens = MemoryTokenStore();
  final api = ApiClient(
    tokens: tokens,
    deviceId: 'kontrak-alur-$urut',
    onUnauthorized: () {},
  );
  final storage = Dio();
  final telepon =
      '0813${(DateTime.now().millisecondsSinceEpoch + urut) % 100000000}'
          .padRight(12, '0');
  await api.post('/auth/otp', data: {'telepon': telepon});
  final masuk = await api.post(
    '/auth/otp/verifikasi',
    data: {'telepon': telepon, 'kode': '123456', 'nama_perangkat': 'Kontrak'},
  ) as Json;
  await tokens.write(masuk['token'] as String);

  final dokumen = (await api.get('/persetujuan/terbaru') as List).cast<Json>();
  await api.post(
    '/persetujuan',
    data: {
      'persetujuan': [
        for (final d in dokumen) {'jenis': d['jenis'], 'versi': d['versi']},
      ],
    },
    options: ApiClient.idempotent(newIdempotencyKey()),
  );
  await api.post(
    '/me/peran',
    data: {'peran': peran},
    options: ApiClient.idempotent(newIdempotencyKey()),
  );

  // Warna unik per jalan dan per akun: NIK tiruan diturunkan dari foto KTP.
  final warna = (DateTime.now().microsecondsSinceEpoch * 7 + urut) & 0xFFFFFF;
  final ktp = await unggahFoto(api, storage, 'FOTO_KTP', _png(warna));
  final swafoto = await unggahFoto(
    api,
    storage,
    'SWAFOTO_KTP',
    _png(warna ^ 0x0F0F0F),
  );
  await api.post(
    '/verifikasi',
    data: {'foto_ktp_id': ktp, 'swafoto_ktp_id': swafoto},
    options: ApiClient.idempotent(newIdempotencyKey()),
  );
  final diri = await unggahFoto(
    api,
    storage,
    'FOTO_DIRI',
    _png(warna ^ 0x00FF00),
  );
  final rumah = await unggahFoto(
    api,
    storage,
    'FOTO_RUMAH',
    _png(warna ^ 0xFF0000),
  );
  var akun = Akun.fromJson(
    await api.put(
      '/me/profil',
      data: {
        'foto_diri_id': diri,
        'foto_rumah_id': rumah,
        'lokasi': _rumah,
        'alamat': 'Jl. Kontrak No. $urut',
      },
    ) as Json,
  );

  if (peran == 'PEKERJA') {
    final art = [
      for (final k in await api.get('/kategori') as List)
        Kategori.fromJson(k as Json),
    ].firstWhere((k) => k.nama == 'ART' || k.periodik);
    await api.put(
      '/me/pekerja',
      data: {
        'hari_tersedia': ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'],
        'kategori': [
          {'kategori_id': art.id, 'titik_awal': 2000000},
        ],
      },
    );
    await unggahBerkas(api, storage, 'VIDEO_PERKENALAN', _mp4(12), 'video/mp4');
    akun = Akun.fromJson(await api.get('/me') as Json);
    if (akun.langkahUntuk(peran) == 'BAYAR_REGISTRASI') {
      // Di luar masa perkenalan: bayar lewat simulasi QRIS (hanya non-produksi).
      final t = Tagihan.fromJson(
        await api.post(
          '/tagihan',
          data: {'jenis': 'REGISTRASI'},
          options: ApiClient.idempotent(newIdempotencyKey()),
        ) as Json,
      );
      await api.post('/dev/qris/${t.id}/bayar');
      akun = Akun.fromJson(await api.get('/me') as Json);
    }
  }
  return _Pengguna(api, akun);
}

void main() {
  test(
    'dua pihak dari pendaftaran sampai pekerjaan disepakati terbaca oleh model aplikasi',
    () async {
      final majikan = await _akunSiap('MAJIKAN', 1);
      final pekerja = await _akunSiap('PEKERJA', 2);
      expect(majikan.akun.langkahUntuk('MAJIKAN'), isNull);
      expect(pekerja.akun.langkahUntuk('PEKERJA'), isNull);
      expect(majikan.akun.statusVerifikasi, 'TERVERIFIKASI');

      // Job majikan.
      final kategori = [
        for (final k in await majikan.api.get('/kategori') as List)
          Kategori.fromJson(k as Json),
      ];
      final art = kategori.firstWhere((k) => k.nama == 'ART' || k.periodik);
      final job = Job.fromJson(
        await majikan.api.post(
          '/job',
          data: {
            'kategori_id': art.id,
            'titik_awal': 2000000,
            'mulai_kerja': DateTime.now()
                .toUtc()
                .add(const Duration(days: 3))
                .toIso8601String(),
            'pola_kerja': 'HARIAN',
            'biaya_admin_ditanggung': 'MAJIKAN',
          },
          options: ApiClient.idempotent(newIdempotencyKey()),
        ) as Json,
      );
      expect(job.status, 'TERBUKA');
      Job.fromJson(await majikan.api.get('/job/${job.id}') as Json);
      final jobSaya = await majikan.api.getPage('/me/job', Job.fromJson);
      expect(jobSaya.items.map((j) => j.id), contains(job.id));

      // Kandidat dan profilnya, dengan konteks job.
      final kandidat = await majikan.api.getPage(
        '/job/${job.id}/kandidat',
        Kandidat.fromJson,
      );
      expect(kandidat.items, isNotEmpty);
      final profilId = kandidat.items.first.profil.id;
      ProfilPublik.fromJson(
        await majikan.api.get('/profil/$profilId', query: {'job_id': job.id})
            as Json,
      );
      await majikan.api.getPage(
        '/profil/$profilId/ulasan',
        UlasanProfil.fromJson,
      );

      // Pekerja menemukan job itu dan mengajukan.
      final cari = await pekerja.api.getPage('/job', KartuJob.fromJson);
      expect(cari.items.map((k) => k.id), contains(job.id));
      await pekerja.api.getPage(
        '/jelajah',
        KartuTerbatas.fromJson,
        query: {'peran': 'PEKERJA'},
      );
      final ajuan = Booking.fromJson(
        await pekerja.api.post(
          '/booking',
          data: {'job_id': job.id},
          options: ApiClient.idempotent(newIdempotencyKey()),
        ) as Json,
      );

      // Majikan melihat dan menyetujui.
      final masuk = await majikan.api.getPage(
        '/booking',
        Booking.fromJson,
        query: {'peran': 'MAJIKAN'},
      );
      expect(masuk.items.map((b) => b.id), contains(ajuan.id));
      // PRD §12.1: kartu tindakan muncul dulu untuk pihak yang bukan pembayar.
      Future<List> kartu(_Pengguna s, String peran) async =>
          ((await s.api.get('/beranda', query: {'peran': peran})
                      as Json)['kartu_tindakan']
                  as List)
              .where((k) => (k as Json)['jenis'] == 'AJUAN_MENUNGGU')
              .toList();
      expect(await kartu(pekerja, 'PEKERJA'), isNotEmpty);
      expect(await kartu(majikan, 'MAJIKAN'), isEmpty);
      // Pembayar biaya admin (majikan) menyetujui terakhir: tombolnya nonaktif dengan alasan sampai pekerja setuju.
      final menunggu = masuk.items.firstWhere((b) => b.id == ajuan.id);
      expect(menunggu.aksi.tersedia, isNot(contains('SETUJUI')));
      expect(menunggu.aksi.alasanNonaktif['SETUJUI'], isNotEmpty);
      expect(ajuan.aksi.tersedia, contains('SETUJUI'));
      await pekerja.api.post(
        '/booking/${ajuan.id}/setujui',
        options: ApiClient.idempotent(newIdempotencyKey()),
      );
      final siap = Booking.fromJson(
        await majikan.api.get('/booking/${ajuan.id}') as Json,
      );
      expect(siap.aksi.tersedia, contains('SETUJUI'));
      expect(await kartu(majikan, 'MAJIKAN'), isNotEmpty);
      await majikan.api.post(
        '/booking/${ajuan.id}/setujui',
        options: ApiClient.idempotent(newIdempotencyKey()),
      );
      final sepakat = Booking.fromJson(
        await majikan.api.get('/booking/${ajuan.id}') as Json,
      );
      expect(sepakat.labelStatus, isNotEmpty);

      // Pekerjaan disepakati di kedua sisi.
      for (final (p, peran) in [(majikan, 'MAJIKAN'), (pekerja, 'PEKERJA')]) {
        final daftar = await p.api.getPage(
          '/penugasan',
          Penugasan.fromJson,
          query: {'peran': peran},
        );
        expect(daftar.items, isNotEmpty, reason: 'penugasan $peran');
        Penugasan.fromJson(
          await p.api.get('/penugasan/${daftar.items.first.id}') as Json,
        );
      }

      // Chat dua arah.
      final percakapan = await pekerja.api.getPage('/percakapan', (j) => j);
      expect(percakapan.items, isNotEmpty);
      final idChat = percakapan.items.first['id'] as String;
      await pekerja.api.post(
        '/percakapan/$idChat/pesan',
        data: {'isi': 'Halo, saya siap mulai.'},
        options: ApiClient.idempotent(newIdempotencyKey()),
      );
      final pesan = await majikan.api.getPage(
        '/percakapan/$idChat/pesan',
        (j) => j,
      );
      expect(pesan.items.first['isi'], 'Halo, saya siap mulai.');
      expect(pesan.items.first['dari_saya'], isFalse);

      // Tagihan, langganan, paket, notifikasi.
      await majikan.api.getPage('/tagihan', Tagihan.fromJson);
      await pekerja.api.getPage('/tagihan', Tagihan.fromJson);
      LanggananInfo.fromJson(await majikan.api.get('/langganan') as Json);
      final paket = await majikan.api.get('/paket') as List;
      for (final p in paket) {
        Paket.fromJson(p as Json);
      }
      final notifikasi = await pekerja.api.getPage('/notifikasi', (j) => j);
      expect(notifikasi.items, isNotEmpty);
      for (final n in notifikasi.items) {
        expect(n['tujuan'], isA<String>());
      }
    },
    skip: _live ? false : 'butuh backend: --dart-define=LIVE_API=true',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
