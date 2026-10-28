import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';

// ---------------------------------------------------------------- Agreement

class Agreement {
  const Agreement({
    required this.id,
    required this.applicationId,
    required this.version,
    required this.rate,
    required this.unit,
    required this.periodCount,
    required this.startDate,
    required this.proposedBy,
    this.seekerApprovedAt,
    this.assistantApprovedAt,
    this.bookingId,
  });

  factory Agreement.fromJson(Map<String, dynamic> j) => Agreement(
    id: j['id'] as String,
    applicationId: j['application_id'] as String,
    version: j['version'] as int,
    rate: j['rate'] as int,
    unit: PeriodUnit.from(j['period_unit'] as String?),
    periodCount: j['period_count'] as int,
    startDate: parseApiTime(j['start_date'] as String),
    proposedBy: Role.from(j['proposed_by'] as String?) ?? Role.seeker,
    seekerApprovedAt: j['seeker_approved_at'] == null
        ? null
        : parseApiTime(j['seeker_approved_at'] as String),
    assistantApprovedAt: j['assistant_approved_at'] == null
        ? null
        : parseApiTime(j['assistant_approved_at'] as String),
    bookingId: j['booking_id'] as String?,
  );

  final String id;
  final String applicationId;
  final int version; // Setuju hanya valid untuk versi terbaru
  final int rate; // rupiah per periode
  final PeriodUnit unit;
  final int periodCount;
  final DateTime startDate;
  final Role proposedBy;
  final DateTime? seekerApprovedAt;
  final DateTime? assistantApprovedAt;
  final String? bookingId;

  bool approvedBy(Role r) =>
      (r == Role.seeker ? seekerApprovedAt : assistantApprovedAt) != null;
  bool get isAgreed => seekerApprovedAt != null && assistantApprovedAt != null;
  bool canApprove(Role r) => !isAgreed && !approvedBy(r);
  bool canCounter(Role r) => !isAgreed;

  Agreement copyWith({
    int? version,
    int? rate,
    PeriodUnit? unit,
    int? periodCount,
    DateTime? startDate,
    Role? proposedBy,
    DateTime? seekerApprovedAt,
    DateTime? assistantApprovedAt,
    bool clearApprovals = false,
    String? bookingId,
  }) => Agreement(
    id: id,
    applicationId: applicationId,
    version: version ?? this.version,
    rate: rate ?? this.rate,
    unit: unit ?? this.unit,
    periodCount: periodCount ?? this.periodCount,
    startDate: startDate ?? this.startDate,
    proposedBy: proposedBy ?? this.proposedBy,
    seekerApprovedAt: clearApprovals
        ? null
        : seekerApprovedAt ?? this.seekerApprovedAt,
    assistantApprovedAt: clearApprovals
        ? null
        : assistantApprovedAt ?? this.assistantApprovedAt,
    bookingId: bookingId ?? this.bookingId,
  );
}

class AgreementInput {
  const AgreementInput({
    required this.rate,
    required this.unit,
    required this.periodCount,
    required this.startDate,
  });

  final int rate;
  final PeriodUnit unit;
  final int periodCount;
  final DateTime startDate;

  Map<String, dynamic> toJson() => {
    'rate': rate,
    'period_unit': unit.name,
    'period_count': periodCount,
    'start_date': toApiTime(startDate),
  };
}

// ------------------------------------------------------------------- Period

enum PeriodStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  unknown;

  static PeriodStatus from(String? s) => enumFromWire(values, s, unknown);

  String get label => switch (this) {
    scheduled => 'Terjadwal',
    inProgress => 'Sedang berjalan',
    completed => 'Selesai',
    cancelled => 'Dibatalkan',
    unknown => 'Status tidak dikenal',
  };

  bool get isFinal => this == completed || this == cancelled;
}

/// Jadwal satu periode kerja. Tanpa tagihan: gaji dibayar langsung antar pihak.
class BookingPeriod {
  const BookingPeriod({
    required this.id,
    required this.bookingId,
    required this.index,
    required this.start,
    required this.end,
    required this.amount,
    required this.status,
  });

  factory BookingPeriod.fromJson(Map<String, dynamic> j) => BookingPeriod(
    id: j['id'] as String,
    bookingId: j['booking_id'] as String,
    index: j['index'] as int,
    start: parseApiTime(j['start'] as String),
    end: parseApiTime(j['end'] as String),
    amount: j['amount'] as int,
    status: PeriodStatus.from(j['status'] as String?),
  );

  final String id;
  final String bookingId;
  final int index; // 1-based
  final DateTime start;
  final DateTime end;
  final int amount; // gaji per periode yang disepakati
  final PeriodStatus status;

  BookingPeriod copyWith({PeriodStatus? status, int? amount}) => BookingPeriod(
    id: id,
    bookingId: bookingId,
    index: index,
    start: start,
    end: end,
    amount: amount ?? this.amount,
    status: status ?? this.status,
  );
}

// ------------------------------------------------------------------ Booking

enum BookingStatus {
  active,
  completed,
  cancelled,
  unknown;

  static BookingStatus from(String? s) => enumFromWire(values, s, unknown);

  String get label => switch (this) {
    active => 'Berjalan',
    completed => 'Selesai',
    cancelled => 'Dibatalkan',
    unknown => 'Status tidak dikenal',
  };

  bool get canCancel => this == active;
  bool get canRate => this == completed;
}

class Booking {
  const Booking({
    required this.id,
    required this.applicationId,
    required this.listingTitle,
    required this.seeker,
    required this.assistant,
    required this.rate,
    required this.unit,
    required this.periodCount,
    required this.startDate,
    required this.status,
    required this.periods,
    this.conversationId,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'] as String,
    applicationId: j['application_id'] as String,
    listingTitle: j['listing_title'] as String,
    seeker: UserCard.fromJson(j['seeker'] as Map<String, dynamic>),
    assistant: UserCard.fromJson(j['assistant'] as Map<String, dynamic>),
    rate: j['rate'] as int,
    unit: PeriodUnit.from(j['period_unit'] as String?),
    periodCount: j['period_count'] as int,
    startDate: parseApiTime(j['start_date'] as String),
    status: BookingStatus.from(j['status'] as String?),
    periods: [
      for (final p in j['periods'] as List)
        BookingPeriod.fromJson(p as Map<String, dynamic>),
    ],
    conversationId: j['conversation_id'] as String?,
  );

  final String id;
  final String applicationId;
  final String listingTitle;
  final UserCard seeker;
  final UserCard assistant;
  final int rate;
  final PeriodUnit unit;
  final int periodCount;
  final DateTime startDate;
  final BookingStatus status;
  final List<BookingPeriod> periods;
  final String? conversationId;

  /// Period yang sedang atau akan berjalan.
  BookingPeriod? get nextPeriod {
    for (final p in periods) {
      if (!p.status.isFinal) return p;
    }
    return null;
  }

  Booking copyWith({
    BookingStatus? status,
    List<BookingPeriod>? periods,
    int? rate,
  }) => Booking(
    id: id,
    applicationId: applicationId,
    listingTitle: listingTitle,
    seeker: seeker,
    assistant: assistant,
    rate: rate ?? this.rate,
    unit: unit,
    periodCount: periodCount,
    startDate: startDate,
    status: status ?? this.status,
    periods: periods ?? this.periods,
    conversationId: conversationId,
  );
}
