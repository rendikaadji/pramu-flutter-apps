import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/rating/domain/rating.dart';
import 'package:pramu_apps/features/rating/domain/rating_repository.dart';

class ApiRatingRepository implements RatingRepository {
  ApiRatingRepository(this._api);
  final ApiClient _api;

  @override
  Future<BookingReviews> forBooking(String bookingId) async =>
      BookingReviews.fromJson(
        await _api.get('/bookings/$bookingId/reviews') as Json,
      );

  @override
  Future<Review> submit(
    String bookingId, {
    required int stars,
    String? comment,
  }) async => Review.fromJson(
    await _api.post(
      '/bookings/$bookingId/reviews',
      data: {'stars': stars, 'comment': ?comment},
    ) as Json,
  );

  @override
  Future<Paged<Review>> reviewsOf(String userId, {String? cursor}) =>
      _api.getPage(
        '/users/$userId/reviews',
        Review.fromJson,
        query: {'cursor': ?cursor},
      );
}
