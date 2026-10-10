import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/time.dart';

enum VerificationStatus {
  none, // belum pernah kirim (klien saja)
  pending,
  verified,
  rejected,
  unknown;

  static VerificationStatus from(String? s) => enumFromWire(values, s, unknown);

  String get label => switch (this) {
    none => 'Belum diverifikasi',
    pending => 'Menunggu tinjauan',
    verified => 'Terverifikasi',
    rejected => 'Ditolak',
    unknown => 'Status tidak dikenal',
  };

  bool get isVerified => this == verified;
  bool get canUpload => this == none || this == rejected;
}

/// Dipakai untuk KTP+selfie (`/verification`) dan SKCK (`/me/skck`).
class Verification {
  const Verification({
    this.status = VerificationStatus.none,
    this.rejectReason,
    this.submittedAt,
  });

  factory Verification.fromJson(Map<String, dynamic> j) => Verification(
    status: VerificationStatus.from(j['status'] as String?),
    rejectReason: j['reject_reason'] as String?,
    submittedAt: j['submitted_at'] == null
        ? null
        : parseApiTime(j['submitted_at'] as String),
  );

  final VerificationStatus status;
  final String? rejectReason;
  final DateTime? submittedAt;
}
