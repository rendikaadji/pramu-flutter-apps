import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/features/akun/baca_ktp.dart';

/// RGBA seragam [w]x[h] dengan nilai abu [g], lalu [garis] membuat pola tepi tajam (huruf) di tengahnya.
Uint8List _piksel(int w, int h, int g, {bool garis = false}) {
  final p = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      final v = garis && (x ~/ 2) % 2 == 0 ? g - 80 : g;
      p[i] = p[i + 1] = p[i + 2] = v.clamp(0, 255);
      p[i + 3] = 255;
    }
  }
  return p;
}

void main() {
  final sekarang = DateTime(2026, 11, 24);

  group('periksaNik', () {
    test('NIK sah lolos', () {
      expect(periksaNik('3171011203900001', sekarang: sekarang), isNull);
      // Perempuan: hari ditambah 40.
      expect(periksaNik('3171015203900001', sekarang: sekarang), isNull);
    });

    test('provinsi, bulan, tanggal, dan panjang yang salah ditolak', () {
      for (final salah in [
        '9971011203900001',
        '3171011213900001',
        '3171013102900001',
        '317101120390000',
        '31710112039000AB',
      ]) {
        expect(
          periksaNik(salah, sekarang: sekarang),
          contains('NIK tidak valid'),
          reason: salah,
        );
      }
    });

    test('di bawah 18 tahun ditolak, tepat 18 tahun lolos', () {
      expect(
        periksaNik('3171011203150001', sekarang: sekarang),
        'Usia minimal 18 tahun.',
      );
      expect(periksaNik('3171012411080001', sekarang: sekarang), isNull);
      expect(
        periksaNik('3171012511080001', sekarang: sekarang),
        'Usia minimal 18 tahun.',
      );
    });
  });

  group('uraiKtp', () {
    test('NIK dan nama pada baris yang sama dengan labelnya', () {
      final h = uraiKtp(
        'PROVINSI DKI JAKARTA\nNIK : 3171011203900001\nNama : Siti Rahayu\nTempat/Tgl Lahir : JAKARTA',
        sekarang: sekarang,
      );
      expect(h.nik, '3171011203900001');
      expect(h.nama, 'SITI RAHAYU');
    });

    test(
      'nama di baris berikutnya dan NIK dengan spasi serta salah baca O/I',
      () {
        final h = uraiKtp(
          'NIK\n3171 O1I2 0390 OOO1\nNama\nBUDI SANTOSO',
          sekarang: sekarang,
        );
        expect(h.nik, '3171011203900001');
        expect(h.nama, 'BUDI SANTOSO');
      },
    );

    test(
      'susunan kolom: label dulu, isi kemudian; nama adalah isi pertama',
      () {
        final h = uraiKtp(
          'PROVINSI DKI JAKARTA\nJAKARTA SELATAN\nNIK\n:\n3171011203900001\nNama\nTempat/Tgl Lahir\nJenis kelamin\nBUDI DWIJA PUTRA\nJAKARTA, 12-03-1990\nLAKI-LAKI',
          sekarang: sekarang,
        );
        expect(h.nik, '3171011203900001');
        expect(h.nama, 'BUDI DWIJA PUTRA');
      },
    );

    test('isi bukan nama (agama, status) tidak diambil sebagai nama', () {
      final h = uraiKtp(
        'NIK : 3171011203900001\nLAKI-LAKI\nISLAM\nKAWIN\nWNI',
        sekarang: sekarang,
      );
      expect(h.nama, isNull);
    });

    test('baris label lain tidak dianggap nama', () {
      final h = uraiKtp(
        'Nama\nTempat/Tgl Lahir : JAKARTA, 12-03-1990\nJenis Kelamin : LAKI-LAKI',
        sekarang: sekarang,
      );
      expect(h.nama, isNull);
    });

    test('deretan 16 angka yang bukan NIK sah diabaikan', () {
      final h = uraiKtp('No. 1234567890123456\nNama : ANI', sekarang: sekarang);
      expect(h.nik, isNull);
      expect(h.nama, 'ANI');
    });

    test('teks kosong tidak menghasilkan apa pun', () {
      final h = uraiKtp('');
      expect(h.nik, isNull);
      expect(h.nama, isNull);
    });
  });

  group('nilaiKualitas', () {
    test('foto gelap ditolak', () {
      expect(
        nilaiKualitas(_piksel(100, 100, 20, garis: true), 100, 100),
        contains('gelap'),
      );
    });

    test('foto silau ditolak', () {
      expect(
        nilaiKualitas(_piksel(100, 100, 255), 100, 100),
        contains('pantulan'),
      );
    });

    test('foto rata tanpa tepi (buram) ditolak', () {
      expect(
        nilaiKualitas(_piksel(100, 100, 150), 100, 100),
        contains('buram'),
      );
    });

    test(
      'bercak putih kecil di bingkai (pantulan) ditolak walau tepinya tajam',
      () {
        final p = _piksel(100, 100, 170, garis: true);
        // Blok 14x14 (sekitar 2% bingkai) menjadi putih: pantulan lokal di atas kartu.
        for (var y = 10; y < 24; y++) {
          for (var x = 10; x < 24; x++) {
            final i = (y * 100 + x) * 4;
            p[i] = p[i + 1] = p[i + 2] = 255;
          }
        }
        expect(nilaiKualitas(p, 100, 100), contains('pantulan'));
      },
    );

    test('kartu putih dengan teks tajam bukan silau', () {
      // Latar 255 dan garis 175: tepi sangat tajam walau lebih dari 25% piksel putih.
      expect(
        nilaiKualitas(_piksel(100, 100, 255, garis: true), 100, 100),
        isNull,
      );
    });

    test('foto terang dengan tepi tajam lolos', () {
      expect(
        nilaiKualitas(_piksel(100, 100, 170, garis: true), 100, 100),
        isNull,
      );
    });
  });
}
