import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';

/// Perkiraan pembatalan, semua angka dari server (§5c belum final).
class RefundPreview {
  const RefundPreview({
    required this.assistantEntitlement,
    required this.fee,
    required this.refundToSeeker,
  });

  factory RefundPreview.fromJson(Map<String, dynamic> j) => RefundPreview(
    assistantEntitlement: j['assistant_entitlement'] as int,
    fee: j['fee'] as int,
    refundToSeeker: j['refund_to_seeker'] as int,
  );

  final int assistantEntitlement;
  final int fee;
  final int refundToSeeker;
}

abstract interface class PaymentRepository {
  /// Buat tagihan period. [idempotencyKey] = satu per niat bayar, pakai ulang saat retry.
  /// 409 `PERIOD_INVALID_STATE` bila bukan `awaiting_payment`.
  Future<Invoice> startPayment(
    String periodId, {
    required String idempotencyKey,
  });

  /// Cek status ke server (sumber kebenaran). `paid` hanya bila server bilang.
  Future<BookingPeriod> checkStatus(String periodId);

  Future<BookingPeriod> confirmComplete(String periodId);

  Future<RefundPreview> cancelPreview(String bookingId);
  Future<Booking> cancel(String bookingId, {required String reason});
}
