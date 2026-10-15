import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/payment/domain/payment_repository.dart';

class ApiPaymentRepository implements PaymentRepository {
  ApiPaymentRepository(this._api);
  final ApiClient _api;

  @override
  Future<Invoice> startPayment(
    String periodId, {
    required String idempotencyKey,
  }) async => Invoice.fromJson(
    await _api.post(
      '/booking-periods/$periodId/pay',
      options: ApiClient.idempotent(idempotencyKey),
    ) as Json,
  );

  @override
  Future<BookingPeriod> checkStatus(String periodId) async =>
      BookingPeriod.fromJson(
        await _api.get('/booking-periods/$periodId') as Json,
      );

  @override
  Future<BookingPeriod> confirmComplete(String periodId) async =>
      BookingPeriod.fromJson(
        await _api.post('/booking-periods/$periodId/confirm-complete') as Json,
      );

  @override
  Future<RefundPreview> cancelPreview(String bookingId) async =>
      RefundPreview.fromJson(
        await _api.get('/bookings/$bookingId/cancel-preview') as Json,
      );

  @override
  Future<Booking> cancel(String bookingId, {required String reason}) async =>
      Booking.fromJson(
        await _api.post('/bookings/$bookingId/cancel', data: {'reason': reason})
            as Json,
      );
}
