import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/rating/domain/rating.dart';

abstract interface class RatingRepository {
  Future<BookingReviews> forBooking(String bookingId);

  /// Tidak bisa diedit. 409 `BOOKING_INVALID_STATE` bila booking belum selesai / sudah dinilai.
  Future<Review> submit(
    String bookingId, {
    required int stars,
    String? comment,
  });

  /// Hanya ulasan `revealed`.
  Future<Paged<Review>> reviewsOf(String userId, {String? cursor});
}
