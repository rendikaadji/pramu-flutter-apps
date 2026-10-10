import 'package:pramu_apps/features/verification/domain/verification.dart';

typedef Progress = void Function(double fraction);

abstract interface class VerificationRepository {
  Future<Verification> current();

  /// Unggah KTP + selfie (path file lokal, sudah dikompres <= 5 MB). Hapus file setelah sukses.
  Future<Verification> submit({
    required String ktpPath,
    required String selfiePath,
    required String nik,
    Progress? onProgress,
  });

  Future<Verification> skck();
  Future<Verification> uploadSkck(String path, {Progress? onProgress});
}
