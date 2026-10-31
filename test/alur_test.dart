import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show InkResponse;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/app.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/shared/app_ui/rating_stars.dart';
import 'package:pramu_apps/shared/app_ui/url_launch.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/memory_token_store.dart';

const _booking = '01a18f68-e59f-739f-bdb4-b73f89d91566';

/// Backend tiruan per rute: `METODE /path` → body JSON. Mencatat setiap permintaan.
class _Backend implements HttpClientAdapter {
  _Backend(this.rute);
  final Map<String, Object? Function(RequestOptions)> rute;
  final panggilan = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? _,
    Future<void>? _,
  ) async {
    panggilan.add(o);
    final h = rute['${o.method} ${o.path}'];
    if (h == null) {
      return ResponseBody.fromString(
        jsonEncode({
          'error': {'code': 'NOT_FOUND', 'message': 'Tidak ada', 'fields': {}},
        }),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    final body = h(o);
    return body == null
        ? ResponseBody.fromString('', 204)
        : ResponseBody.fromString(
            jsonEncode(body),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _akun({String? langkah}) => {
  'id': '01a18f68-0000-7000-8000-000000000001',
  'nama_depan': 'Dewi',
  'inisial': 'L.',
  'bahasa': 'id',
  'peran': ['MAJIKAN'],
  'status_verifikasi': 'TERVERIFIKASI',
  'langkah_onboarding_berikutnya': langkah,
};

const _profil = {
  'id': '01a18f68-0000-7000-8000-000000000002',
  'nama': 'Rina W.',
  'foto_url': null,
  'terverifikasi': true,
  'rating': 4.5,
  'jumlah_ulasan': 2,
  'jumlah_selesai': 3,
  'pembatalan_120_hari': 0,
  'badge_peringatan': false,
  'baru': false,
  'kecamatan': 'Setiabudi',
};

Map<String, Object?> _bookingJson({bool sudah = false}) => {
  'id': _booking,
  'aksi_tersedia': sudah ? <String>[] : ['SETUJUI', 'TOLAK'],
  'akibat': {
    'SETUJUI': 'Setelah kalian berdua setuju, pekerjaan disepakati.',
    'TOLAK': 'Ajuan ditolak.',
  },
  'alasan_nonaktif': <String, String>{},
  'job': {'judul': 'Bersih rumah'},
  'pihak_lain': _profil,
  'status': 'MENUNGGU_LOCK',
  'label_status': 'Menunggu persetujuan',
  'harga_kesepakatan': {'nilai': 80000, 'teks': 'Rp80.000'},
  'penanggung_biaya': null,
  'biaya_admin': {'nilai': 0, 'teks': 'Rp0'},
  'persetujuan': {
    'majikan_at': sudah ? '2026-10-31T00:46:00Z' : null,
    'pekerja_at': null,
  },
  'batas_lock': {'sampai': '2026-11-01T00:46:00Z', 'teks': '23 jam lagi'},
  'tagihan_menunggu': null,
  'percakapan_id': null,
};

Future<_Backend> _pasang(
  WidgetTester tester,
  Map<String, Object? Function(RequestOptions)> rute, {
  String? token = 'token-uji',
  List<Override> tambahan = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final backend = _Backend(rute);
  final tokens = MemoryTokenStore(token);
  final dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl))
    ..httpClientAdapter = backend;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
        ...tambahan,
        apiClientProvider.overrideWithValue(
          ApiClient(
            tokens: tokens,
            deviceId: 'uji',
            onUnauthorized: () {},
            dio: dio,
          ),
        ),
      ],
      child: const PramuApp(),
    ),
  );
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  setUpAll(initLocale);

  testWidgets(
    'akun yang belum menyetujui ketentuan dibawa ke layar persetujuan',
    (tester) async {
      await _pasang(tester, {
        'GET /me': (_) => _akun(langkah: 'PERSETUJUAN'),
        'GET /persetujuan/terbaru': (_) => {
          'data': [
            {
              'jenis': 'KETENTUAN_LAYANAN',
              'versi': '1.0',
              'url': 'https://pramu.example/syarat',
            },
          ],
        },
      });

      expect(find.text('Sebelum mulai'), findsOneWidget);
      expect(find.text('Ketentuan layanan'), findsOneWidget);
    },
  );

  testWidgets(
    'akun yang belum KTP bisa Lihat dulu: kartu terbatas tanpa data pribadi, lalu Lihat lebih jauh',
    (tester) async {
      final backend = await _pasang(tester, {
        'GET /me': (_) => _akun(langkah: 'KTP'),
        'GET /jelajah': (o) => {
          'data': [
            {
              'kategori': {'id': 'k1', 'kode': 'ART', 'nama': 'ART'},
              'kelompok_jarak': '3-5',
              'rating': null,
              'jumlah_ulasan': 0,
              'jumlah_selesai': 2,
              'baru': true,
              'ongkos_ditanggung': null,
            },
          ],
          'next_cursor': null,
          'sisa_hari_ini': 29,
        },
      });

      await tester.tap(
        find.text('Lihat dulu pekerja dan pekerjaan di sekitarmu'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Sisa kartu yang bisa dilihat hari ini: 29'),
        findsOneWidget,
      );
      expect(find.text('ART'), findsOneWidget);
      expect(find.text('3-5 km · Baru · 2 pekerjaan selesai'), findsOneWidget);
      expect(backend.panggilan.last.queryParameters['peran'], 'MAJIKAN');

      await tester.tap(find.text('Lihat lebih jauh'));
      await tester.pumpAndSettle();
      expect(backend.panggilan.last.queryParameters['lebih_jauh'], 'true');
    },
  );

  testWidgets(
    'masuk lewat WhatsApp balik: kode, buka WhatsApp, pesan terbaca, lalu Ya lanjut membuat sesi',
    (tester) async {
      var diterima = false;
      Uri? dibuka;
      const id = '01a18f68-0000-7000-8000-0000000000aa';
      final backend = await _pasang(
        tester,
        {
          'GET /auth/jalur': (_) => {'wa': true, 'otp': true},
          'POST /auth/wa/tantangan': (_) => {
            'id': id,
            'kode': 'K7M2QX',
            'token': 'token-tantangan',
            'nomor_pramu': '6281200000000',
            'tautan_wa': 'https://wa.me/6281200000000?text=Kode%20K7M2QX',
            'berlaku_sampai': '2026-11-01T00:05:00Z',
          },
          'GET /auth/wa/tantangan/$id': (_) => {
            'status': diterima ? 'DITERIMA' : 'MENUNGGU',
            'telepon_tersamar': diterima ? '••••7890' : null,
          },
          'POST /auth/wa/tantangan/$id/lanjut': (_) => {
            'token': 'token-sesi',
            'akun': _akun(),
          },
          'GET /me': (_) => _akun(),
          'GET /beranda': (_) => {
            'kartu_tindakan': [],
            'penugasan_berjalan': [],
            'job_saya': [],
          },
        },
        token: null,
        tambahan: [
          urlLauncherProvider.overrideWithValue((uri, mode) async {
            dibuka = uri;
            return true;
          }),
        ],
      );

      await tester.tap(find.text('Masuk lewat WhatsApp'));
      await tester.pumpAndSettle();
      expect(find.text('K7M2QX'), findsOneWidget);

      await tester.tap(find.text('Buka WhatsApp'));
      await tester.pump();
      expect(dibuka?.host, 'wa.me');

      // Pesan masuk: pemeriksaan berkala memakai token tantangan dan menampilkan nomor tersamar.
      diterima = true;
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(
        find.text('Nomor ••••7890 terbaca. Lanjut masuk dengan nomor ini?'),
        findsOneWidget,
      );
      final cek = backend.panggilan.lastWhere(
        (o) => o.method == 'GET' && o.path == '/auth/wa/tantangan/$id',
      );
      expect(cek.headers['X-Tantangan-Token'], 'token-tantangan');

      await tester.tap(find.text('Ya, lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Masuk ke Pramu'), findsNothing);
      expect(find.text('Halo, Dewi'), findsOneWidget);
    },
  );

  testWidgets(
    'tautan selain wa.me tidak dibuka, dan OTP tetap bisa dipilih bila tersedia',
    (tester) async {
      var dibuka = false;
      const id = '01a18f68-0000-7000-8000-0000000000ab';
      await _pasang(
        tester,
        {
          'GET /auth/jalur': (_) => {'wa': true, 'otp': true},
          'POST /auth/wa/tantangan': (_) => {
            'id': id,
            'kode': 'AB23CD',
            'token': 't',
            'nomor_pramu': '6281200000000',
            'tautan_wa': 'https://contoh.example/wa',
            'berlaku_sampai': '2026-11-01T00:05:00Z',
          },
          'GET /auth/wa/tantangan/$id': (_) => {
            'status': 'MENUNGGU',
            'telepon_tersamar': null,
          },
        },
        token: null,
        tambahan: [
          urlLauncherProvider.overrideWithValue((uri, mode) async {
            dibuka = true;
            return true;
          }),
        ],
      );

      await tester.tap(find.text('Masuk lewat WhatsApp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka WhatsApp'));
      await tester.pumpAndSettle();
      expect(dibuka, isFalse);
      expect(find.textContaining('WhatsApp tidak bisa dibuka'), findsOneWidget);

      await tester.ensureVisible(find.text('Pakai kode OTP saja'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pakai kode OTP saja'));
      await tester.pumpAndSettle();
      expect(find.text('Kirim kode'), findsOneWidget);
    },
  );

  testWidgets('Akun: Ajak tetangga membuka pesan WhatsApp dari server', (
    tester,
  ) async {
    Uri? dibuka;
    await _pasang(
      tester,
      {
        'GET /me': (_) => _akun(),
        'GET /beranda': (_) => {
          'kartu_tindakan': [],
          'penugasan_berjalan': [],
          'job_saya': [],
        },
        'GET /me/undangan': (_) => {
          'wilayah': 'Kota Bekasi',
          'tautan': 'https://pramu.example/undang/32.75',
          'pesan': 'Ayo gabung Pramu di Kota Bekasi: https://pramu.example/undang/32.75',
          'tautan_wa': 'https://wa.me/?text=Ayo%20gabung%20Pramu',
        },
      },
      tambahan: [
        urlLauncherProvider.overrideWithValue((uri, mode) async {
          dibuka = uri;
          return true;
        }),
      ],
    );

    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajak tetangga lewat WhatsApp'));
    await tester.pumpAndSettle();

    expect(dibuka?.host, 'wa.me');
    expect(dibuka?.queryParameters['text'], 'Ayo gabung Pramu');
  });

  testWidgets(
    'Ganti nomor HP: bukti dari nomor sekarang lalu nomor baru, konfirmasi, dan sesi tetap masuk',
    (tester) async {
      var lamaDiterima = false;
      var baruDiterima = false;
      const idLama = '01a18f68-0000-7000-8000-0000000000b1';
      const idBaru = '01a18f68-0000-7000-8000-0000000000b2';
      final backend = await _pasang(tester, {
        'GET /me': (_) => _akun(),
        'GET /beranda': (_) => {
          'kartu_tindakan': [],
          'penugasan_berjalan': [],
          'job_saya': [],
        },
        'POST /me/telepon/wa/tantangan': (o) {
          final lama = (o.data as Map)['arah'] == 'LAMA';
          return {
            'id': lama ? idLama : idBaru,
            'kode': lama ? 'LAMA23' : 'BARU23',
            'token': lama ? 'tok-lama' : 'tok-baru',
            'nomor_pramu': '6281200000000',
            'tautan_wa': 'https://wa.me/6281200000000?text=Kode',
            'berlaku_sampai': '2026-11-01T00:05:00Z',
          };
        },
        'GET /auth/wa/tantangan/$idLama': (_) => {
          'status': lamaDiterima ? 'DITERIMA' : 'MENUNGGU',
          'telepon_tersamar': lamaDiterima ? '••••7890' : null,
        },
        'GET /auth/wa/tantangan/$idBaru': (_) => {
          'status': baruDiterima ? 'DITERIMA' : 'MENUNGGU',
          'telepon_tersamar': baruDiterima ? '••••0111' : null,
        },
        'POST /me/telepon/wa': (_) => _akun(),
      });

      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ganti nomor HP'));
      await tester.tap(find.text('Ganti nomor HP'));
      await tester.pumpAndSettle();

      // Langkah 2 baru muncul setelah bukti dari nomor sekarang diterima.
      expect(find.text('Langkah 2: dari nomor yang baru'), findsNothing);
      await tester.tap(find.text('Mulai dari nomor sekarang'));
      await tester.pumpAndSettle();
      expect(find.text('LAMA23'), findsOneWidget);
      lamaDiterima = true;
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Nomor ••••7890 terbaca.'), findsOneWidget);

      await tester.ensureVisible(find.text('Mulai dari nomor baru'));
      await tester.tap(find.text('Mulai dari nomor baru'));
      await tester.pumpAndSettle();
      baruDiterima = true;
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.textContaining('dari ••••7890 ke ••••0111'), findsOneWidget);

      await tester.ensureVisible(find.text('Ya, ganti nomor'));
      await tester.tap(find.text('Ya, ganti nomor'));
      await tester.pumpAndSettle();

      final ganti = backend.panggilan.lastWhere(
        (o) => o.method == 'POST' && o.path == '/me/telepon/wa',
      );
      expect(ganti.data, {
        'id_lama': idLama,
        'token_lama': 'tok-lama',
        'id_baru': idBaru,
        'token_baru': 'tok-baru',
      });
      expect(find.text('Nomor HP berhasil diganti.'), findsOneWidget);
    },
  );

  testWidgets(
    'Tagihan: daftar, detail dengan QRIS, lalu berubah lunas setelah dibayar',
    (tester) async {
      var lunas = false;
      const id = '01a18f68-0000-7000-8000-0000000000c1';
      Map<String, Object?> tagihan() => {
        'id': id,
        'judul': 'Fee pekerjaan sekali datang',
        'nominal': {'nilai': 30000, 'teks': 'Rp30.000'},
        'status': lunas ? 'LUNAS' : 'MENUNGGU',
        'qr_payload': lunas ? null : '000201010212QRIS-UJI',
        'berlaku_sampai': {
          'sampai': '2026-11-01T00:30:00Z',
          'teks': '25 menit lagi',
        },
        'referensi': lunas ? 'REF-123' : null,
      };
      await _pasang(tester, {
        'GET /me': (_) => _akun(),
        'GET /beranda': (_) => {
          'kartu_tindakan': [],
          'penugasan_berjalan': [],
          'job_saya': [],
        },
        'GET /tagihan': (_) => {
          'data': [tagihan()],
          'next_cursor': null,
        },
        'GET /tagihan/$id': (_) => tagihan(),
      });

      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tagihan dan pembayaran'));
      await tester.tap(find.text('Tagihan dan pembayaran'));
      await tester.pumpAndSettle();
      expect(find.text('Fee pekerjaan sekali datang'), findsOneWidget);
      expect(find.text('Menunggu bayar'), findsOneWidget);

      await tester.tap(find.text('Fee pekerjaan sekali datang'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.textContaining('25 menit lagi'), findsOneWidget);

      lunas = true;
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
      expect(
        find.text('Pembayaran sudah kami terima. Terima kasih.'),
        findsOneWidget,
      );
      expect(find.text('Nomor referensi: REF-123'), findsOneWidget);
    },
  );

  testWidgets(
    'Langganan: majikan memilih paket, tagihan QRIS terbuka dengan kunci idempoten',
    (tester) async {
      const paketId = '01a18f68-0000-7000-8000-0000000000d1';
      const tagihanId = '01a18f68-0000-7000-8000-0000000000d2';
      final backend = await _pasang(tester, {
        'GET /me': (_) => _akun(),
        'GET /beranda': (_) => {
          'kartu_tindakan': [],
          'penugasan_berjalan': [],
          'job_saya': [],
        },
        'GET /langganan': (_) => {
          'paket': null,
          'status': null,
          'berakhir': null,
          'job_aktif': 1,
          'batas_job_aktif': 2,
          'upgrade': [],
        },
        'GET /paket': (_) => [
          {
            'id': paketId,
            'kode': 'BULANAN',
            'nama': 'Paket Bulanan',
            'durasi_bulan': 1,
            'harga': {'nilai': 49000, 'teks': 'Rp49.000'},
            'batas_job_aktif': 3,
          },
        ],
        'POST /langganan': (_) => {
          'id': tagihanId,
          'judul': 'Langganan Paket Bulanan',
          'nominal': {'nilai': 49000, 'teks': 'Rp49.000'},
          'status': 'MENUNGGU',
          'qr_payload': '000201QRIS-LANGGANAN',
          'berlaku_sampai': {
            'sampai': '2026-11-01T00:30:00Z',
            'teks': '25 menit lagi',
          },
        },
        'GET /tagihan/$tagihanId': (_) => {
          'id': tagihanId,
          'judul': 'Langganan Paket Bulanan',
          'nominal': {'nilai': 49000, 'teks': 'Rp49.000'},
          'status': 'MENUNGGU',
          'qr_payload': '000201QRIS-LANGGANAN',
          'berlaku_sampai': {
            'sampai': '2026-11-01T00:30:00Z',
            'teks': '25 menit lagi',
          },
        },
      });

      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Langganan'));
      await tester.tap(find.text('Langganan'));
      await tester.pumpAndSettle();
      expect(find.text('Job aktif: 1 dari 2'), findsOneWidget);
      expect(find.text('Paket Bulanan · 1 bulan'), findsOneWidget);

      await tester.ensureVisible(find.text('Pilih paket').last);
      await tester.tap(find.text('Pilih paket').last);
      await tester.pumpAndSettle();

      final beli = backend.panggilan.lastWhere(
        (o) => o.method == 'POST' && o.path == '/langganan',
      );
      expect(beli.data, {'paket_id': paketId});
      expect(beli.headers['Idempotency-Key'], isNotNull);
      expect(find.text('Bayar tagihan'), findsOneWidget);
      expect(find.text('Rp49.000'), findsWidgets);
    },
  );

  testWidgets(
    'Pekerjaan: beri ulasan lalu laporkan pihak lain dengan kunci idempoten',
    (tester) async {
      const id = '01a18f68-0000-7000-8000-0000000000e1';
      final backend = await _pasang(tester, {
        'GET /me': (_) => _akun(),
        'GET /beranda': (_) => {
          'kartu_tindakan': [],
          'penugasan_berjalan': [
            {
              'id': id,
              'judul': 'Bersih rumah',
              'label_status': 'Selesai',
              'pihak_lain': _profil,
            },
          ],
          'job_saya': [],
        },
        'GET /penugasan/$id': (_) => {
          'id': id,
          'judul': 'Bersih rumah',
          'label_status': 'Selesai',
          'pihak_lain': _profil,
          'aksi_tersedia': <String>[],
        },
        'POST /penugasan/$id/ulasan': (_) => {},
        'POST /laporan': (_) => {},
      });

      await tester.tap(find.textContaining('Bersih rumah'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Beri ulasan'));
      await tester.tap(find.text('Beri ulasan'));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(RatingStars),
              matching: find.byType(InkResponse),
            )
            .at(3),
      );
      await tester.pump();
      await tester.tap(find.text('Kirim ulasan'));
      await tester.pumpAndSettle();
      final ulasan = backend.panggilan.lastWhere(
        (o) => o.method == 'POST' && o.path == '/penugasan/$id/ulasan',
      );
      expect(ulasan.data, {'bintang': 4});
      expect(ulasan.headers['Idempotency-Key'], isNotNull);

      await tester.ensureVisible(find.text('Laporkan'));
      await tester.tap(find.text('Laporkan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Identitas palsu'));
      await tester.tap(find.text('Identitas palsu'));
      await tester.pump();
      await tester.ensureVisible(find.text('Kirim laporan'));
      await tester.tap(find.text('Kirim laporan'));
      await tester.pumpAndSettle();
      final laporan = backend.panggilan.lastWhere(
        (o) => o.method == 'POST' && o.path == '/laporan',
      );
      expect(laporan.data, {
        'terlapor_profil_id': '01a18f68-0000-7000-8000-000000000002',
        'kategori': 'IDENTITAS_PALSU',
      });
    },
  );

  testWidgets('Beranda menampilkan banner masa perkenalan dari server', (
    tester,
  ) async {
    await _pasang(tester, {
      'GET /me': (_) => _akun(),
      'GET /perkenalan': (_) => {
        'aktif': true,
        'mulai_berbayar': null,
        'pesan': 'Selama masa perkenalan, Pramu gratis digunakan.',
      },
      'GET /beranda': (_) => {
        'kartu_tindakan': [],
        'penugasan_berjalan': [],
        'job_saya': [],
      },
    });

    expect(
      find.text('Selama masa perkenalan, Pramu gratis digunakan.'),
      findsOneWidget,
    );
  });

  testWidgets('Beranda tanpa banner bila masa perkenalan sudah berakhir', (
    tester,
  ) async {
    await _pasang(tester, {
      'GET /me': (_) => _akun(),
      'GET /perkenalan': (_) => {
        'aktif': false,
        'mulai_berbayar': null,
        'pesan': 'Masa perkenalan sudah berakhir.',
      },
      'GET /beranda': (_) => {
        'kartu_tindakan': [],
        'penugasan_berjalan': [],
        'job_saya': [],
      },
    });

    expect(find.text('Masa perkenalan sudah berakhir.'), findsNothing);
  });

  testWidgets(
    'kartu tindakan di Beranda membuka ajuan, lalu Setujui mengirim POST dengan Idempotency-Key',
    (tester) async {
      var disetujui = false;
      final backend = await _pasang(tester, {
        'GET /me': (_) => _akun(),
        'GET /beranda': (_) => {
          'kartu_tindakan': [
            {
              'jenis': 'AJUAN_MENUNGGU',
              'batas': {
                'sampai': '2026-11-01T00:46:00Z',
                'teks': '23 jam lagi',
              },
              'judul': 'Ajuan Bersih rumah menunggu persetujuanmu',
              'akibat_jika_diam': 'Jika diam, ajuan gugur.',
              'tombol': [
                {
                  'aksi': 'SETUJUI',
                  'label': 'Tinjau dan setujui',
                  'tujuan': '/booking/$_booking',
                },
              ],
              'sumber_id': _booking,
            },
          ],
          'penugasan_berjalan': [],
          'job_saya': [],
        },
        'GET /booking/$_booking': (_) => _bookingJson(sudah: disetujui),
        'POST /booking/$_booking/setujui': (_) {
          disetujui = true;
          return {'booking': _bookingJson(sudah: true), 'tagihan': null};
        },
      });

      expect(
        find.text('Ajuan Bersih rumah menunggu persetujuanmu'),
        findsOneWidget,
      );
      expect(find.text('23 jam lagi'), findsOneWidget);

      await tester.tap(find.text('Tinjau dan setujui'));
      await tester.pumpAndSettle();
      expect(find.text('Rp80.000'), findsOneWidget);
      // Status persetujuan memakai nama, data detail ditandai terkunci, dan pekerjaan sekali datang tanpa biaya admin.
      expect(find.text('Rina W. belum setuju'), findsOneWidget);
      expect(find.text('Kamu belum setuju'), findsOneWidget);
      expect(
        find.textContaining('Terbuka setelah disepakati', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('Biaya admin'), findsNothing);
      expect(
        find.text('Setelah kalian berdua setuju, pekerjaan disepakati.'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Setujui').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setujui').first);
      await tester.pumpAndSettle();
      // Dialog konfirmasi mengulang akibat; tombol konfirmasinya juga "Setujui".
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Setujui ajuan ini?'), findsOneWidget);
      await tester.tap(find.text('Setujui').last);
      await tester.pumpAndSettle();

      final post = backend.panggilan.singleWhere((o) => o.method == 'POST');
      expect(post.path, '/booking/$_booking/setujui');
      expect(post.headers['Idempotency-Key'], isNotNull);
      expect(find.text('Kamu sudah setuju'), findsOneWidget);
    },
  );
}
