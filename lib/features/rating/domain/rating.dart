import 'package:pramu_apps/core/time.dart';

class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.reviewerName,
    required this.stars,
    required this.createdAt,
    this.comment,
    this.isAuto = false,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: j['id'] as String,
    bookingId: j['booking_id'] as String,
    reviewerName: j['reviewer_name'] as String,
    stars: j['stars'] as int,
    createdAt: parseApiTime(j['created_at'] as String),
    comment: j['comment'] as String?,
    isAuto: j['is_auto'] as bool? ?? false,
  );

  final String id;
  final String bookingId;
  final String reviewerName;
  final int stars; // 1-5
  final DateTime createdAt;
  final String? comment;
  final bool isAuto; // tampil label "Otomatis"
}

/// Status penilaian satu booking dari sudut pandang pengguna aktif.
class BookingReviews {
  const BookingReviews({required this.deadline, this.mine, this.theirs});

  factory BookingReviews.fromJson(Map<String, dynamic> j) => BookingReviews(
    deadline: parseApiTime(j['deadline'] as String),
    mine: j['mine'] == null
        ? null
        : Review.fromJson(j['mine'] as Map<String, dynamic>),
    theirs: j['theirs'] == null
        ? null
        : Review.fromJson(j['theirs'] as Map<String, dynamic>),
  );

  final DateTime deadline; // batas 7 hari
  final Review? mine;

  /// Null selama disembunyikan server (belum `revealed`).
  final Review? theirs;

  bool get canSubmit => mine == null;
}
