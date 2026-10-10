import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/features/verification/domain/verification_repository.dart';

/// Review KTP: `pending` -> hasil muncul pada pembacaan ke-2 `current()`.
/// NIK berakhiran `0000` -> `rejected` (dengan alasan); lainnya -> `verified`.
/// SKCK: `pending` -> `verified` pada pembacaan berikutnya `skck()`.
class MockVerificationRepository implements VerificationRepository {
  MockVerificationRepository(this._b);
  final MockBackend _b;

  Verification _dto(MockUser u) => Verification(
    status: u.verification,
    rejectReason: u.verification == VerificationStatus.rejected
        ? u.rejectReason
        : null,
    submittedAt: u.verification == VerificationStatus.none ? null : _b.now(),
  );

  @override
  Future<Verification> current() => _b.run(() {
    final u = _b.me;
    if (u.verification == VerificationStatus.pending &&
        ++u.verificationPolls >= 2) {
      u.verification = u.rejectReason != null
          ? VerificationStatus.rejected
          : VerificationStatus.verified;
      _b.notify(
        u.id,
        NotificationType.verification,
        'Hasil verifikasi',
        u.verification.label,
        null,
      );
    }
    return _dto(u);
  });

  @override
  Future<Verification> submit({
    required String ktpPath,
    required String selfiePath,
    required String nik,
    Progress? onProgress,
  }) => _b.run(() {
    final u = _b.me;
    final err = validateNik(nik);
    if (err != null) {
      apiFail(422, 'VALIDATION_FAILED', 'Periksa kembali data Anda.', {
        'nik': [err],
      });
    }
    if (!u.verification.canUpload) {
      apiFail(409, 'VERIFICATION_INVALID_STATE', 'Verifikasi sudah dikirim.');
    }
    onProgress?.call(1);
    u.verification = VerificationStatus.pending;
    u.verificationPolls = 0;
    u.rejectReason = nik.endsWith('0000')
        ? 'Foto KTP buram. Ambil ulang dengan pencahayaan cukup.'
        : null;
    return _dto(u);
  });

  @override
  Future<Verification> skck() => _b.run(() {
    final u = _b.me;
    if (u.skck.status == VerificationStatus.pending) {
      u.skck = const Verification(status: VerificationStatus.verified);
    }
    return u.skck;
  });

  @override
  Future<Verification> uploadSkck(String path, {Progress? onProgress}) =>
      _b.run(() {
        final u = _b.me;
        if (!u.skck.status.canUpload) {
          apiFail(409, 'VERIFICATION_INVALID_STATE', 'SKCK sudah dikirim.');
        }
        onProgress?.call(1);
        return u.skck = Verification(
          status: VerificationStatus.pending,
          submittedAt: _b.now(),
        );
      });
}
