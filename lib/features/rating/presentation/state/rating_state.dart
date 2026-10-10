import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/booking/data/booking_providers.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/rating/data/rating_providers.dart';
import 'package:pramu_apps/features/rating/domain/rating.dart';

class RatingView {
  const RatingView(this.booking, this.reviews);
  final Booking booking;
  final BookingReviews reviews;
}

class RatingNotifier extends AsyncNotifier<RatingView> {
  RatingNotifier(this.bookingId);
  final String bookingId;

  @override
  Future<RatingView> build() async {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    final booking = ref.read(bookingRepositoryProvider).booking(bookingId);
    final reviews = ref.read(ratingRepositoryProvider).forBooking(bookingId);
    return RatingView(await booking, await reviews);
  }

  /// Melempar ApiException ke layar (409/422); sukses memuat ulang ringkasan.
  Future<void> submit(int stars, String comment) async {
    await ref
        .read(ratingRepositoryProvider)
        .submit(bookingId, stars: stars, comment: comment);
    ref.invalidateSelf();
    await future;
  }
}

final ratingProvider = AsyncNotifierProvider.autoDispose
    .family<RatingNotifier, RatingView, String>(RatingNotifier.new);

class ReviewsState {
  const ReviewsState(this.items, this.nextCursor);
  final List<Review> items;
  final String? nextCursor;
}

class UserReviewsNotifier extends AsyncNotifier<ReviewsState> {
  UserReviewsNotifier(this.userId);
  final String userId;

  @override
  Future<ReviewsState> build() async {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    final Paged<Review> p = await ref
        .read(ratingRepositoryProvider)
        .reviewsOf(userId);
    return ReviewsState(p.items, p.nextCursor);
  }

  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || cur.nextCursor == null) return;
    final p = await ref
        .read(ratingRepositoryProvider)
        .reviewsOf(userId, cursor: cur.nextCursor);
    state = AsyncData(ReviewsState([...cur.items, ...p.items], p.nextCursor));
  }
}

final userReviewsProvider = AsyncNotifierProvider.autoDispose
    .family<UserReviewsNotifier, ReviewsState, String>(UserReviewsNotifier.new);
