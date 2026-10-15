import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/platform/sensitive_files.dart';

const maxPhotoBytes = 5 * 1024 * 1024;

/// Foto sensitif terkompres: `bytes` untuk pratinjau (Image.memory), `path` untuk unggah.
class CapturedPhoto {
  const CapturedPhoto(this.path, this.bytes);
  final String path;
  final Uint8List bytes;
}

class PhotoException implements Exception {
  const PhotoException(this.message, {this.permissionDenied = false});
  final String message;
  final bool permissionDenied;
}

enum PhotoSource { camera, gallery }

/// Pengambilan foto KTP/selfie/SKCK (MOB-SEC-05): kamera langsung, kompres <= 5 MB tanpa EXIF,
/// simpan hanya di direktori internal app, hapus setelah dipakai.
abstract interface class PhotoService {
  /// null = pengguna membatalkan. Melempar [PhotoException].
  Future<CapturedPhoto?> capture(PhotoSource source, {bool front = false});

  Future<void> delete(CapturedPhoto? photo);
}

class ImagePickerPhotoService implements PhotoService {
  final _picker = ImagePicker();

  @override
  Future<CapturedPhoto?> capture(
    PhotoSource source, {
    bool front = false,
  }) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        preferredCameraDevice: front ? CameraDevice.front : CameraDevice.rear,
        requestFullMetadata: false,
      );
    } on PlatformException catch (e) {
      final denied = e.code.endsWith('_access_denied');
      throw PhotoException(
        denied
            ? 'Izin kamera belum aktif. Aktifkan di Pengaturan, atau pilih foto dari galeri.'
            : 'Kamera belum bisa dibuka. Coba lagi.',
        permissionDenied: denied,
      );
    }
    if (picked == null) return null;
    try {
      Uint8List? bytes;
      for (final q in const [85, 70, 55, 40]) {
        bytes = await FlutterImageCompress.compressWithFile(
          picked.path,
          quality: q,
          minWidth: 1600,
          minHeight: 1600,
          keepExif: false,
        );
        if (bytes != null && bytes.length <= maxPhotoBytes) break;
      }
      if (bytes == null || bytes.length > maxPhotoBytes) {
        throw const PhotoException(
          'Foto terlalu besar. Ambil ulang dengan jarak sedikit lebih jauh.',
        );
      }
      final dir = sensitiveDir()..createSync(recursive: true);
      final file = File('${dir.path}${Platform.pathSeparator}${ulid()}.jpg');
      await file.writeAsBytes(bytes, flush: true);
      return CapturedPhoto(file.path, bytes);
    } on PhotoException {
      rethrow;
    } on Object {
      throw const PhotoException('Foto belum bisa diproses. Coba ambil ulang.');
    } finally {
      try {
        await File(picked.path).delete();
      } on Object {
        // salinan sementara picker; bersihkan saat start berikutnya
      }
    }
  }

  @override
  Future<void> delete(CapturedPhoto? photo) async {
    if (photo == null) return;
    try {
      await File(photo.path).delete();
    } on Object {
      // sudah hilang
    }
  }
}
