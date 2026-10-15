import 'dart:io';

/// Satu direktori internal (cache app, bukan galeri/penyimpanan eksternal) untuk foto
/// KTP/selfie/SKCK terkompres. Dihapus setelah unggah/batal dan disapu saat start (MOB-SEC-05).
Directory sensitiveDir() => Directory(
  '${Directory.systemTemp.path}${Platform.pathSeparator}pramu_sensitive',
);

Future<void> sweepSensitiveFiles() async {
  try {
    final d = sensitiveDir();
    if (d.existsSync()) await d.delete(recursive: true);
  } on FileSystemException {
    // sisa dibersihkan pada start berikutnya
  }
}
