import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/time.dart';

enum ReportType {
  behavior,
  fraud,
  payment,
  workMismatch,
  other,
  unknown;

  static ReportType from(String? s) => enumFromWire(values, s, unknown);

  String get label => switch (this) {
    behavior => 'Perilaku',
    fraud => 'Penipuan',
    payment => 'Pembayaran',
    workMismatch => 'Pekerjaan tidak sesuai',
    other => 'Lainnya',
    unknown => 'Lainnya',
  };
}

enum ReportStatus {
  received,
  reviewing,
  needsInfo,
  decided,
  unknown;

  static ReportStatus from(String? s) => enumFromWire(values, s, unknown);

  String get label => switch (this) {
    received => 'Diterima',
    reviewing => 'Sedang ditinjau',
    needsInfo => 'Perlu info tambahan',
    decided => 'Sudah diputuskan',
    unknown => 'Status tidak dikenal',
  };

  bool get canAddEvidence =>
      this == received || this == reviewing || this == needsInfo;
}

class ChatShareConsent {
  const ChatShareConsent({required this.expiresAt, this.revoked = false});

  factory ChatShareConsent.fromJson(Map<String, dynamic> j) => ChatShareConsent(
    expiresAt: parseApiTime(j['expires_at'] as String),
    revoked: j['revoked'] as bool? ?? false,
  );

  final DateTime expiresAt; // 7 hari
  final bool revoked;
}

class Report {
  const Report({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.bookingId,
    this.periodId,
    this.decision,
    this.share,
  });

  factory Report.fromJson(Map<String, dynamic> j) => Report(
    id: j['id'] as String,
    type: ReportType.from(j['type'] as String?),
    description: j['description'] as String,
    status: ReportStatus.from(j['status'] as String?),
    createdAt: parseApiTime(j['created_at'] as String),
    bookingId: j['booking_id'] as String?,
    periodId: j['period_id'] as String?,
    decision: j['decision'] as String?,
    share: j['share'] == null
        ? null
        : ChatShareConsent.fromJson(j['share'] as Map<String, dynamic>),
  );

  final String id;
  final ReportType type;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;
  final String? bookingId;
  final String? periodId;
  final String? decision; // ringkasan release/refund/split
  final ChatShareConsent? share;

  Report copyWith({ReportStatus? status, ChatShareConsent? share}) => Report(
    id: id,
    type: type,
    description: description,
    status: status ?? this.status,
    createdAt: createdAt,
    bookingId: bookingId,
    periodId: periodId,
    decision: decision,
    share: share ?? this.share,
  );
}

class ReportInput {
  const ReportInput({
    required this.type,
    required this.description,
    this.bookingId,
    this.periodId,
    this.evidencePaths = const [],
  });

  final ReportType type;
  final String description;
  final String? bookingId;
  final String? periodId; // bila ada: period & booking jadi `disputed`
  final List<String> evidencePaths; // foto bukti pilihan sendiri
}
