import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/platform/sensitive_files.dart';

/// Memilih satu foto bukti; hasil sudah dikompres dan EXIF dibuang. Mengembalikan path file sementara.
abstract interface class EvidencePicker {
  Future<String?> pick({required bool camera});
}

class DeviceEvidencePicker implements EvidencePicker {
  const DeviceEvidencePicker();

  @override
  Future<String?> pick({required bool camera}) async {
    final x = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (x == null) return null;
    try {
      // direktori yang sama dengan KTP/selfie agar ikut disapu (MOB-SEC-05)
      final dir = sensitiveDir()..createSync(recursive: true);
      final out = '${dir.path}${Platform.pathSeparator}bukti_${uuidV4()}.jpg';
      final r = await FlutterImageCompress.compressAndGetFile(
        x.path,
        out,
        quality: 80,
        minWidth: 1600,
        minHeight: 1600,
        keepExif: false,
      );
      return r?.path;
    } finally {
      // x.path = salinan cache picker (bukan berkas asli galeri)
      await deleteTemp(x.path);
    }
  }
}

final evidencePickerProvider = Provider<EvidencePicker>(
  (ref) => const DeviceEvidencePicker(),
);

Future<void> deleteTemp(String path) async {
  try {
    await File(path).delete();
  } on Object {
    // sudah hilang
  }
}
