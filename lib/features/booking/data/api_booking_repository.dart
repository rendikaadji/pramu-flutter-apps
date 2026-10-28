import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/booking/domain/booking_repository.dart';

class ApiBookingRepository implements BookingRepository {
  ApiBookingRepository(this._api);
  final ApiClient _api;

  @override
  Future<Agreement> propose(String applicationId, AgreementInput input) async =>
      Agreement.fromJson(
        await _api.post(
          '/applications/$applicationId/agreement',
          data: input.toJson(),
        ) as Json,
      );

  @override
  Future<Agreement> agreement(String id) async =>
      Agreement.fromJson(await _api.get('/agreements/$id') as Json);

  @override
  Future<Agreement?> byApplication(String applicationId) async {
    try {
      return Agreement.fromJson(
        await _api.get('/applications/$applicationId/agreement') as Json,
      );
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Agreement> approve(String id, {required int version}) async =>
      Agreement.fromJson(
        await _api.post('/agreements/$id/approve', data: {'version': version})
            as Json,
      );

  @override
  Future<Agreement> counter(String id, AgreementInput input) async =>
      Agreement.fromJson(
        await _api.post('/agreements/$id/counter', data: input.toJson())
            as Json,
      );

  @override
  Future<List<Booking>> bookings() async => [
    for (final b in await _api.get('/bookings') as List)
      Booking.fromJson(b as Json),
  ];

  @override
  Future<Booking> booking(String id) async =>
      Booking.fromJson(await _api.get('/bookings/$id') as Json);

  @override
  Future<Booking> cancel(String bookingId, {required String reason}) async =>
      Booking.fromJson(
        await _api.post('/bookings/$bookingId/cancel', data: {'reason': reason})
            as Json,
      );
}
