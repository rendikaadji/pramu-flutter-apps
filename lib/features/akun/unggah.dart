import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';

/// Ambil satu foto dari kamera (atau galeri). Diperkecil dan dikompres di perangkat; berkas sementara dihapus segera
/// setelah dibaca (MOB-SEC-05). null = pengguna batal.
typedef AmbilFoto = Future<Uint8List?> Function({bool galeri});

final ambilFotoProvider = Provider<AmbilFoto>(
  (_) => ({bool galeri = false}) async {
    final picker = ImagePicker();
    var x = await picker.pickImage(
      source: galeri ? ImageSource.gallery : ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
      requestFullMetadata: false,
    );
    // HP dengan RAM kecil mematikan layar aplikasi selagi kamera terbuka; fotonya tetap ada di plugin dan diambil di sini.
    // Tanpa ini pengguna sudah memotret tetapi layar kembali kosong.
    if (x == null && Platform.isAndroid) {
      final hilang = await picker.retrieveLostData();
      x = hilang.file ?? hilang.files?.firstOrNull;
    }
    if (x == null) return null;
    final isi = await x.readAsBytes();
    try {
      await File(x.path).delete();
    } on FileSystemException {
      // Sisa dibersihkan sweepSensitiveFiles / sistem.
    }
    return isi;
  },
);

/// Galat lokasi yang bisa dibaca pengguna.
class LokasiGagal implements Exception {
  const LokasiGagal(this.pesan);
  final String pesan;
}

typedef AmbilLokasi = Future<({double lintang, double bujur})> Function();

/// Titik rumah dari GPS, sekali saja (tidak dilacak).
final ambilLokasiProvider = Provider<AmbilLokasi>(
  (_) => () async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LokasiGagal('Nyalakan lokasi (GPS) di HP, lalu coba lagi.');
    }
    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }
    if (izin == LocationPermission.denied ||
        izin == LocationPermission.deniedForever) {
      throw const LokasiGagal(
        'Izinkan Pramu memakai lokasi di pengaturan HP, lalu coba lagi.',
      );
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return (lintang: p.latitude, bujur: p.longitude);
    } catch (_) {
      throw const LokasiGagal(
        'Lokasi belum terbaca. Coba di dekat jendela atau di luar rumah.',
      );
    }
  },
);

/// Klien terpisah untuk mengunggah ke URL bertanda tangan: tanpa header Authorization, karena tujuannya storage.
final unggahDioProvider = Provider<Dio>(
  (_) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
    ),
  ),
);

/// Unggah satu foto (PRD §7.3): minta URL, kirim langsung ke storage, lalu minta server memeriksa. Hasil: id berkas.
Future<String> unggahFoto(
  ApiClient api,
  Dio storage,
  String jenis,
  Uint8List isi,
) async {
  final mime = _mime(isi);
  final u = await api.post(
    '/berkas/unggah',
    data: {'jenis': jenis, 'tipe_mime': mime, 'ukuran': isi.length},
  ) as Json;
  try {
    await storage.put<void>(
      u['url_unggah'] as String,
      data: Stream.fromIterable([isi]),
      options: Options(
        headers: {
          Headers.contentTypeHeader: mime,
          Headers.contentLengthHeader: isi.length,
        },
      ),
    );
  } on DioException {
    throw ApiException(
      status: ApiException.network,
      code: 'NETWORK',
      message: 'Foto gagal terkirim. Periksa jaringan lalu coba lagi.',
    );
  }
  final s = await api.post('/berkas/${u['berkas_id']}/selesai') as Json;
  return s['id'] as String;
}

/// Jenis gambar dari byte awal; image_picker dengan kompresi menghasilkan JPEG, tetapi galeri bisa PNG atau HEIC.
String _mime(Uint8List b) {
  if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8) return 'image/jpeg';
  if (b.length > 3 && b[0] == 0x89 && b[1] == 0x50) return 'image/png';
  return 'image/heic';
}
