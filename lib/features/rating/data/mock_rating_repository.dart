import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/rating/domain/rating.dart';
import 'package:pramu_apps/features/rating/domain/rating_repository.dart';

/// Ulasan lawan tersembunyi sampai ulasan sendiri terkirim atau 7 hari setelah kontrak selesai.
class MockRatingRepository implements RatingRepository {
  MockRatingRepository(this._b);
  final MockBackend _b;

  DateTime _deadline(String bookingId) =>
      (_b.completedAt[bookingId] ?? _b.now()).add(const Duration(days: 7));

  bool _revealed(MockReview r) {
    final bid = r.review.bookingId;
    if (!_b.bookings.containsKey(bid)) return true; // riwayat lama
    return _b.reviews.any(
          (o) => o.review.bookingId == bid && o.reviewerId == r.revieweeId,
        ) ||
        !_b.now().isBefore(_deadline(bid));
  }

  @override
  Future<BookingReviews> forBooking(String bookingId) => _b.run(() {
    _b.booking(bookingId);
    final uid = _b.me.id;
    final all = _b.reviews.where((r) => r.review.bookingId == bookingId);
    final mine = all.where((r) => r.reviewerId == uid).firstOrNull;
    final theirs = all.where((r) => r.revieweeId == uid).firstOrNull;
    return BookingReviews(
      deadline: _deadline(bookingId),
      mine: mine?.review,
      theirs: theirs != null && _revealed(theirs) ? theirs.review : null,
    );
  });

  @override
  Future<Review> submit(
    String bookingId, {
    required int stars,
    String? comment,
  }) => _b.run(() {
    final b = _b.booking(bookingId);
    final me = _b.me;
    if (!b.status.canRate ||
        _b.reviews.any(
          (r) => r.review.bookingId == bookingId && r.reviewerId == me.id,
        )) {
      apiFail(409, 'BOOKING_INVALID_STATE', 'Penilaian tidak dapat dikirim.');
    }
    if (stars < 1 || stars > 5) {
      apiFail(422, 'VALIDATION_FAILED', 'Pilih 1 sampai 5 bintang.', {
        'stars': ['Pilih 1 sampai 5 bintang'],
      });
    }
    final other = b.seeker.id == me.id ? b.assistant.id : b.seeker.id;
    final review = Review(
      id: _b.newId(),
      bookingId: bookingId,
      reviewerName: me.name,
      stars: stars,
      comment: comment?.trim().isEmpty ?? true ? null : comment!.trim(),
      createdAt: _b.now(),
    );
    _b.reviews.add(MockReview(review, me.id, other));
    final u = _b.users[other]!;
    u.ratingAvg = (u.ratingAvg * u.ratingCount + stars) / (u.ratingCount + 1);
    u.ratingCount++;
    return review;
  });

  @override
  Future<Paged<Review>> reviewsOf(String userId, {String? cursor}) =>
      _b.run(() {
        _b.me;
        final all = [
          for (final r in _b.reviews)
            if (r.revieweeId == userId && _revealed(r)) r.review,
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return _b.page(all, cursor);
      });
}
