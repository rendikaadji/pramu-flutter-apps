import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Membaca NIK dan nama dari foto KTP di HP, tanpa mengirim foto ke pihak ketiga. Hasilnya hanya petunjuk untuk admin
/// (server tetap memeriksa, dan admin mencocokkan dengan foto), jadi pengguna selalu boleh mengoreksinya.

/// Teks mentah hasil OCR, atau melempar bila OCR tidak tersedia di perangkat ini.
typedef BacaTeks = Future<String> Function(Uint8List foto);

/// null = foto cukup jelas; selain itu pesan yang bisa langsung ditindaklanjuti pengguna.
typedef PeriksaKualitas = Future<String?> Function(Uint8List foto);

final bacaTeksProvider = Provider<BacaTeks>((_) => bacaTeksMlKit);
final periksaKualitasProvider = Provider<PeriksaKualitas>(
  (_) => periksaKualitasFoto,
);

Future<String> bacaTeksMlKit(Uint8List foto) async {
  // ML Kit membaca dari berkas. Berkas sementara dihapus segera karena memuat KTP (MOB-SEC-05).
  final berkas = File(
    '${Directory.systemTemp.path}/ktp_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  final pembaca = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    await berkas.writeAsBytes(foto, flush: true);
    final hasil = await pembaca.processImage(
      InputImage.fromFilePath(berkas.path),
    );
    return hasil.text;
  } finally {
    await pembaca.close();
    try {
      await berkas.delete();
    } on FileSystemException {
      // Dibersihkan sistem.
    }
  }
}

/// Hasil penguraian teks OCR. Keduanya null bila tidak ketemu.
class HasilBacaKtp {
  const HasilBacaKtp({this.nik, this.nama});

  final String? nik;
  final String? nama;
}

/// Kode provinsi yang dipakai di NIK (dua digit pertama); sama dengan sisi server.
const _provinsi = {
  11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 31, 32, 33, 34, 35, 36, 51, 52, 53, //
  61, 62, 63, 64, 65, 71, 72, 73, 74, 75, 76, 81, 82, 91, 92, 93, 94, 95, 96,
};

/// Pesan galat bila NIK tidak masuk akal atau pemiliknya di bawah 18 tahun; null bila sah. Sama dengan aturan server.
String? periksaNik(String nik, {DateTime? sekarang}) {
  if (!RegExp(r'^\d{16}$').hasMatch(nik) ||
      !_provinsi.contains(int.parse(nik.substring(0, 2)))) {
    return 'NIK tidak valid. Periksa 16 angka di KTP.';
  }
  final nu = sekarang ?? DateTime.now();
  var hari = int.parse(nik.substring(6, 8));
  if (hari > 40) hari -= 40;
  final bulan = int.parse(nik.substring(8, 10));
  var tahun = 2000 + int.parse(nik.substring(10, 12));
  if (tahun > nu.year) tahun -= 100;
  final lahir = DateTime(tahun, bulan, hari);
  if (bulan < 1 ||
      bulan > 12 ||
      hari < 1 ||
      lahir.month != bulan ||
      lahir.day != hari) {
    return 'NIK tidak valid. Periksa 16 angka di KTP.';
  }
  var usia = nu.year - lahir.year;
  if (nu.month < lahir.month ||
      (nu.month == lahir.month && nu.day < lahir.day)) {
    usia--;
  }
  return usia < 18 ? 'Usia minimal 18 tahun.' : null;
}

/// Salah baca yang umum pada deretan angka: O→0, I/l/|→1. Hanya dipakai pada token yang panjangnya pas 16.
String _perbaikiAngka(String s) =>
    s.replaceAll(RegExp('[Oo]'), '0').replaceAll(RegExp(r'[Il|]'), '1');

/// Mengambil NIK (16 angka yang lolos pemeriksaan struktur) dan nama dari teks mentah OCR.
HasilBacaKtp uraiKtp(String teks, {DateTime? sekarang}) {
  final baris = teks
      .split(RegExp(r'[\r\n]+'))
      .map((b) => b.trim())
      .where((b) => b.isNotEmpty)
      .toList();

  String? nik;
  var barisNik = -1;
  for (final b in baris) {
    final padat = b.replaceAll(RegExp(r'[\s:.\-]'), '');
    for (final m in RegExp(r'[0-9OoIl|]{16}').allMatches(padat)) {
      final calon = _perbaikiAngka(m.group(0)!);
      if (periksaNik(calon, sekarang: sekarang) == null) {
        nik = calon;
        barisNik = baris.indexOf(b);
        break;
      }
    }
    if (nik != null) break;
  }

  String? nama;
  for (var i = 0; i < baris.length && nama == null; i++) {
    final m = RegExp(
      r'^nama\b[\s:;.\-]*(.*)$',
      caseSensitive: false,
    ).firstMatch(baris[i]);
    if (m == null) continue;
    // Nilai bisa di baris yang sama ("Nama : SITI") atau di baris berikutnya.
    for (final kandidat in [
      m.group(1) ?? '',
      if (i + 1 < baris.length) baris[i + 1],
    ]) {
      final bersih = _bersihkanNama(kandidat);
      if (bersih != null) {
        nama = bersih;
        break;
      }
    }
  }
  // Cadangan: OCR sering mengeluarkan kolom label dulu lalu kolom isi (Nama, Tempat Lahir, ... lalu BUDI, ACEH, ...).
  // Pada KTP, nama adalah isi pertama setelah baris NIK.
  if (nama == null && barisNik >= 0) {
    for (var i = barisNik + 1; i < baris.length; i++) {
      final bersih = _bersihkanNama(baris[i]);
      if (bersih != null && !_bukanNama.hasMatch(bersih)) {
        nama = bersih;
        break;
      }
    }
  }
  return HasilBacaKtp(nik: nik, nama: nama);
}

/// Isi KTP yang bukan nama (agama, status, kewarganegaraan, dan sejenisnya) serta judul kolom.
final _bukanNama = RegExp(
  r'^(laki|perempuan|islam|kristen|katolik|hindu|buddha|budha|konghucu|kawin|belum|cerai|wni|wna|seumur|wiraswasta|pelajar|mahasiswa|karyawan|pns|nama|tempat|jenis|kelamin|gol|darah|alamat|rt|rw|kel|desa|kecamatan|agama|status|perkawinan|pekerjaan|kewarganegaraan|berlaku|hingga|provinsi|kabupaten|kota)\b',
  caseSensitive: false,
);

String? _bersihkanNama(String s) {
  final b = s
      .replaceAll(RegExp(r"[^A-Za-z .,'\-]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  // Baris label lain yang ikut terbaca ("Tempat/Tgl Lahir", "Jenis Kelamin") bukan nama.
  if (RegExp(r'\d').hasMatch(s) ||
      b.length < 3 ||
      RegExp(
        r'^(tempat|jenis|alamat|gol|agama|status|pekerjaan|kewarganegaraan|berlaku|nik)',
        caseSensitive: false,
      ).hasMatch(b)) {
    return null;
  }
  return b.toUpperCase();
}

/// Pemeriksaan kualitas foto sebelum OCR: terlalu kecil, gelap, silau, atau buram. Dihitung di HP dari piksel; tidak butuh
/// OCR. Foto yang tidak bisa didekode dianggap lolos (server menolak berkas rusak) agar tidak menghalangi pengguna.
Future<String?> periksaKualitasFoto(Uint8List foto) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? desc;
  ui.Codec? codec;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(foto);
    desc = await ui.ImageDescriptor.encoded(buffer);
    if (desc.width < 800 && desc.height < 800) {
      return 'Foto terlalu kecil. Dekatkan kamera sampai KTP memenuhi layar.';
    }
    codec = await desc.instantiateCodec(targetWidth: 640);
    final gambar = (await codec.getNextFrame()).image;
    final rgba = await gambar.toByteData();
    final w = gambar.width;
    final h = gambar.height;
    gambar.dispose();
    if (rgba == null || w < 8 || h < 8) return null;
    return nilaiKualitas(rgba.buffer.asUint8List(), w, h);
  } on Exception {
    return null;
  } finally {
    codec?.dispose();
    desc?.dispose();
    buffer?.dispose();
  }
}

/// Ukuran mentah sebuah foto: rata-rata terang (0-255), porsi piksel hampir putih (0-1), dan ketajaman tepi (simpangan
/// baku Laplacian; makin tinggi makin tajam). Dipisah dari ambang agar bisa diukur pada foto contoh.
class UkuranFoto {
  const UkuranFoto({
    required this.terang,
    required this.silau,
    required this.tajam,
  });

  final double terang;
  final double silau;
  final double tajam;

  @override
  String toString() =>
      'terang=${terang.toStringAsFixed(1)} silau=${silau.toStringAsFixed(3)} tajam=${tajam.toStringAsFixed(1)}';
}

/// Ambang penilaian, disetel dari 10 foto contoh di vivo 1727 (3120x4160, kamera bawaan):
/// - Terang: kamera menaikkan eksposur sendiri, foto "redup" tetap 80-87; hanya foto sangat gelap yang kena.
/// - Silau: pantulan nyata menutupi 0,8-0,9% frame, foto lain di bawah 0,1%. Ambang 0,5%. Bingkai yang hampir seluruhnya
///   putih (kartu atau meja putih) tidak dianggap pantulan selama tepi hurufnya tajam.
/// - Buram: foto sengaja goyang 9,5 dan 13,7, foto agak buram 10,1, foto tajam 14,9-29,8. Ambang 14, celahnya tipis.
/// Hanya satu HP dan satu kartu: setel ulang dengan foto dari HP lain.
const ambangGelap = 55.0;
const ambangSilau = 0.005;
const batasBingkaiPutih = 0.30;
const ambangSilauTajam = 15.0;
const ambangBuram = 14.0;
UkuranFoto ukurFoto(Uint8List rgba, int w, int h) {
  final abu = Uint8List(w * h);
  var jumlah = 0;
  var silau = 0;
  for (var i = 0; i < w * h; i++) {
    final g =
        (rgba[i * 4] * 299 + rgba[i * 4 + 1] * 587 + rgba[i * 4 + 2] * 114) ~/
        1000;
    abu[i] = g;
    jumlah += g;
    if (g >= 250) silau++;
  }
  var total = 0.0;
  var totalKuadrat = 0.0;
  var n = 0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final i = y * w + x;
      final lap =
          4 * abu[i] - abu[i - 1] - abu[i + 1] - abu[i - w] - abu[i + w];
      total += lap;
      totalKuadrat += lap * lap;
      n++;
    }
  }
  final rataLap = total / n;
  return UkuranFoto(
    terang: jumlah / (w * h),
    silau: silau / (w * h),
    tajam: math.sqrt(totalKuadrat / n - rataLap * rataLap),
  );
}

/// Inti penilaian pada piksel RGBA (dipisah agar bisa diuji tanpa kamera). null = jelas.
String? nilaiKualitas(Uint8List rgba, int w, int h) {
  final u = ukurFoto(rgba, w, h);
  if (u.terang < ambangGelap) {
    return 'Foto terlalu gelap. Pindah ke tempat yang lebih terang.';
  }
  // Pantulan = bercak putih di bingkai yang selebihnya tidak putih; bingkai serba putih dengan tepi tajam bukan pantulan.
  if (u.silau > ambangSilau &&
      (u.silau < batasBingkaiPutih || u.tajam < ambangSilauTajam)) {
    return 'Ada pantulan cahaya yang menutupi KTP. Miringkan sedikit atau pindah dari cahaya langsung.';
  }
  if (u.tajam < ambangBuram) {
    return 'Foto buram. Tahan HP dengan stabil dan tunggu fokus sebelum memotret.';
  }
  return null;
}
