import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';

/// Rincian biaya DARI SERVER. Klien hanya memformat; jangan dihitung ulang untuk dikirim.
class Fees {
  const Fees({
    required this.amount,
    required this.seekerFee,
    required this.seekerTotal,
    required this.assistantFee,
    required this.assistantReceives,
  });

  factory Fees.fromJson(Map<String, dynamic> j) => Fees(
    amount: j['amount'] as int,
    seekerFee: j['seeker_fee'] as int,
    seekerTotal: j['seeker_total'] as int,
    assistantFee: j['assistant_fee'] as int,
    assistantReceives: j['assistant_receives'] as int,
  );

  final int amount;
  final int seekerFee;
  final int seekerTotal; // yang dibayar pencari
  final int assistantFee;
  final int assistantReceives; // yang diterima asisten
}

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
    required this.fees,
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
    fees: Fees.fromJson(j['fees'] as Map<String, dynamic>),
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
  final Fees fees; // atas total kontrak
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
    Fees? fees,
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
    fees: fees ?? this.fees,
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

enum PeriodAction { pay, confirmComplete, cancel, report, addEvidence }

enum PeriodStatus {
  awaitingPayment,
  expired,
  paid,
  inProgress,
  awaitingConfirmation,
  completed,
  settled,
  cancelled,
  disputed,
  refunded,
  unknown;

  static PeriodStatus from(String? s) => enumFromWire(values, s, unknown);

  /// Label per peran (UIUX §9). Untuk settled asisten, UI menambahkan nominal.
  String labelFor(Role role) {
    final seeker = role == Role.seeker;
    return switch (this) {
      awaitingPayment =>
        seeker ? 'Menunggu pembayaran Anda' : 'Menunggu pembayaran Pencari',
      paid => seeker ? 'Dana ditahan aman' : 'Dana Pencari sudah diamankan',
      inProgress => 'Sedang berjalan',
      awaitingConfirmation =>
        seeker ? 'Konfirmasi pekerjaan selesai' : 'Menunggu konfirmasi Pencari',
      completed || settled => seeker ? 'Selesai' : 'Dana masuk dompet',
      expired => 'Tagihan kedaluwarsa',
      cancelled || refunded => 'Dibatalkan',
      disputed => 'Sedang ditinjau',
      unknown => 'Status tidak dikenal',
    };
  }

  bool get canPay => this == awaitingPayment;
  bool get canConfirmComplete => this == awaitingConfirmation;
  bool get canDispute =>
      this == paid || this == inProgress || this == awaitingConfirmation;
  bool get isFinal =>
      this == settled ||
      this == completed ||
      this == cancelled ||
      this == refunded;

  Set<PeriodAction> actionsFor(Role role) {
    final seeker = role == Role.seeker;
    return {
      if (seeker && canPay) PeriodAction.pay,
      if (seeker && canConfirmComplete) PeriodAction.confirmComplete,
      if (seeker && this == inProgress) PeriodAction.cancel,
      if (canDispute) PeriodAction.report,
      if (this == disputed) PeriodAction.addEvidence,
    };
  }
}

class BookingPeriod {
  const BookingPeriod({
    required this.id,
    required this.bookingId,
    required this.index,
    required this.start,
    required this.end,
    required this.amount,
    required this.serviceFee,
    required this.total,
    required this.status,
    required this.dueAt,
    this.autoReleaseAt,
    this.invoiceId,
    this.paidAt,
  });

  factory BookingPeriod.fromJson(Map<String, dynamic> j) => BookingPeriod(
    id: j['id'] as String,
    bookingId: j['booking_id'] as String,
    index: j['index'] as int,
    start: parseApiTime(j['start'] as String),
    end: parseApiTime(j['end'] as String),
    amount: j['amount'] as int,
    serviceFee: j['service_fee'] as int,
    total: j['total'] as int,
    status: PeriodStatus.from(j['status'] as String?),
    dueAt: parseApiTime(j['due_at'] as String),
    autoReleaseAt: j['auto_release_at'] == null
        ? null
        : parseApiTime(j['auto_release_at'] as String),
    invoiceId: j['invoice_id'] as String?,
    paidAt: j['paid_at'] == null ? null : parseApiTime(j['paid_at'] as String),
  );

  final String id;
  final String bookingId;
  final int index; // 1-based
  final DateTime start;
  final DateTime end;
  final int amount; // hak asisten sebelum fee
  final int serviceFee; // fee pencari (dari server)
  final int total; // yang dibayar pencari (dari server)
  final PeriodStatus status;
  final DateTime dueAt; // batas bayar
  final DateTime? autoReleaseAt; // countdown auto-release dana
  final String? invoiceId;
  final DateTime? paidAt;

  BookingPeriod copyWith({
    PeriodStatus? status,
    DateTime? autoReleaseAt,
    String? invoiceId,
    DateTime? paidAt,
  }) => BookingPeriod(
    id: id,
    bookingId: bookingId,
    index: index,
    start: start,
    end: end,
    amount: amount,
    serviceFee: serviceFee,
    total: total,
    status: status ?? this.status,
    dueAt: dueAt,
    autoReleaseAt: autoReleaseAt ?? this.autoReleaseAt,
    invoiceId: invoiceId ?? this.invoiceId,
    paidAt: paidAt ?? this.paidAt,
  );
}

// ------------------------------------------------------------------ Booking

enum BookingStatus {
  active,
  paused,
  completed,
  cancelled,
  disputed,
  unknown;

  static BookingStatus from(String? s) => enumFromWire(values, s, unknown);

  String get label => switch (this) {
    active => 'Berjalan',
    paused => 'Dijeda, tagihan belum dibayar',
    completed => 'Selesai',
    cancelled => 'Dibatalkan',
    disputed => 'Dalam sengketa',
    unknown => 'Status tidak dikenal',
  };

  bool get canCancel => this == active || this == paused;
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
    required this.fees,
    required this.periods,
    this.conversationId,
    this.pausedUntil,
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
    fees: Fees.fromJson(j['fees'] as Map<String, dynamic>),
    periods: [
      for (final p in j['periods'] as List)
        BookingPeriod.fromJson(p as Map<String, dynamic>),
    ],
    conversationId: j['conversation_id'] as String?,
    pausedUntil: j['paused_until'] == null
        ? null
        : parseApiTime(j['paused_until'] as String),
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
  final Fees fees; // snapshot
  final List<BookingPeriod> periods;
  final String? conversationId;
  final DateTime? pausedUntil;

  /// Period yang paling relevan untuk "Langkah berikutnya".
  BookingPeriod? get nextPeriod {
    for (final p in periods) {
      if (!p.status.isFinal) return p;
    }
    return null;
  }

  Booking copyWith({
    BookingStatus? status,
    List<BookingPeriod>? periods,
    DateTime? pausedUntil,
    bool clearPausedUntil = false,
  }) => Booking(
    id: id,
    applicationId: applicationId,
    listingTitle: listingTitle,
    seeker: seeker,
    assistant: assistant,
    rate: rate,
    unit: unit,
    periodCount: periodCount,
    startDate: startDate,
    status: status ?? this.status,
    fees: fees,
    periods: periods ?? this.periods,
    conversationId: conversationId,
    pausedUntil: clearPausedUntil ? null : pausedUntil ?? this.pausedUntil,
  );
}
