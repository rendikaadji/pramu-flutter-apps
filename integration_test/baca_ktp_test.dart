import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pramu_apps/features/akun/baca_ktp.dart';

/// Gambar KTP tiruan (teks hitam di latar putih, 1600x1000) memakai font perangkat.
Future<Uint8List> _ktpTiruan(List<String> baris) async {
  const w = 1600.0;
  const h = 1000.0;
  final rekam = ui.PictureRecorder();
  final kanvas = Canvas(rekam, const Rect.fromLTWH(0, 0, w, h));
  kanvas.drawRect(
    const Rect.fromLTWH(0, 0, w, h),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  var y = 60.0;
  for (final b in baris) {
    final p = TextPainter(
      text: TextSpan(
        text: b,
        style: const TextStyle(
          color: Color(0xFF000000),
          fontSize: 56,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 120);
    p.paint(kanvas, Offset(60, y));
    y += 110;
  }
  final gambar = await rekam.endRecording().toImage(w.toInt(), h.toInt());
  final png = await gambar.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ML Kit di HP membaca NIK dan nama dari foto KTP tiruan', (
    tester,
  ) async {
    final foto = await tester.runAsync(
      () => _ktpTiruan([
        'PROVINSI DKI JAKARTA',
        'NIK : 3171011203900001',
        'Nama : SITI RAHAYU',
        'Tempat/Tgl Lahir : JAKARTA, 12-03-1990',
        'Alamat : JL. MELATI NO. 3',
      ]),
    );

    final kualitas = await tester.runAsync(() => periksaKualitasFoto(foto!));
    expect(kualitas, isNull, reason: 'foto tajam dan terang harus lolos');

    final teks = await tester.runAsync(() => bacaTeksMlKit(foto!));
    // ignore: avoid_print
    print('TEKS OCR: ${teks!.replaceAll('\n', ' | ')}');
    final hasil = uraiKtp(teks);
    expect(hasil.nik, '3171011203900001');
    expect(hasil.nama, 'SITI RAHAYU');
  });

  testWidgets('foto kosong putih ditolak sebagai buram atau silau', (
    tester,
  ) async {
    final foto = await tester.runAsync(() => _ktpTiruan(const []));
    final kualitas = await tester.runAsync(() => periksaKualitasFoto(foto!));
    expect(kualitas, isNotNull);
  });
}
