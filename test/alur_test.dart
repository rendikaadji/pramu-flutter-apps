import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/app.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/time.dart';
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
  Map<String, Object? Function(RequestOptions)> rute,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final backend = _Backend(rute);
  final tokens = MemoryTokenStore('token-uji');
  final dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl))
    ..httpClientAdapter = backend;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
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
