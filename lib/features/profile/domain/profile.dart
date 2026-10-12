import 'package:pramu_apps/core/models/shared.dart';

/// Ringkasan publik pengguna (kartu kepercayaan). Tidak pernah memuat HP/alamat.
class UserCard {
  const UserCard({
    required this.id,
    required this.name,
    this.photoUrl,
    this.verified = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
  });

  factory UserCard.fromJson(Map<String, dynamic> j) => UserCard(
    id: j['id'] as String,
    name: j['name'] as String,
    photoUrl: j['photo_url'] as String?,
    verified: j['verified'] as bool? ?? false,
    ratingAvg: (j['rating_avg'] as num?)?.toDouble() ?? 0,
    ratingCount: j['rating_count'] as int? ?? 0,
  );

  final String id;
  final String name;
  final String? photoUrl;
  final bool verified;
  final double ratingAvg;
  final int ratingCount;
}

class AssistantProfile {
  const AssistantProfile({
    required this.userId,
    required this.name,
    this.photoUrl,
    this.categories = const [],
    this.experienceYears = 0,
    this.skills = const [],
    this.rate = 0,
    this.unit = PeriodUnit.monthly,
    this.city = '',
    this.available = true,
    this.verified = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.completedJobs = 0,
    this.bio = '',
  });

  factory AssistantProfile.fromJson(Map<String, dynamic> j) => AssistantProfile(
    userId: j['user_id'] as String,
    name: j['name'] as String,
    photoUrl: j['photo_url'] as String?,
    categories: List<String>.from(j['categories'] as List? ?? const []),
    experienceYears: j['experience_years'] as int? ?? 0,
    skills: List<String>.from(j['skills'] as List? ?? const []),
    rate: j['rate'] as int? ?? 0,
    unit: PeriodUnit.from(j['rate_unit'] as String?),
    city: j['city'] as String? ?? '',
    available: j['available'] as bool? ?? true,
    verified: j['verified'] as bool? ?? false,
    ratingAvg: (j['rating_avg'] as num?)?.toDouble() ?? 0,
    ratingCount: j['rating_count'] as int? ?? 0,
    completedJobs: j['completed_jobs'] as int? ?? 0,
    bio: j['bio'] as String? ?? '',
  );

  final String userId;
  final String name;
  final String? photoUrl;
  final List<String> categories;
  final int experienceYears;
  final List<String> skills;
  final int rate; // rupiah per [unit]
  final PeriodUnit unit;
  final String city;
  final bool available;
  final bool verified; // read-only dari server
  final double ratingAvg;
  final int ratingCount;
  final int completedJobs;
  final String bio;

  /// Hanya field yang boleh diubah pengguna.
  Map<String, dynamic> toJson() => {
    'categories': categories,
    'experience_years': experienceYears,
    'skills': skills,
    'rate': rate,
    'rate_unit': unit.name,
    'city': city,
    'available': available,
    'bio': bio,
  };

  /// Meter kelengkapan 0-100 (M-40/M-21).
  int get completeness {
    final done = [
      photoUrl != null,
      categories.isNotEmpty,
      experienceYears > 0,
      skills.isNotEmpty,
      rate > 0,
      city.isNotEmpty,
      bio.isNotEmpty,
    ].where((e) => e).length;
    return (done * 100 / 7).round();
  }

  bool get isValid => categories.isNotEmpty && city.isNotEmpty;

  AssistantProfile withPhoto(String? url) => AssistantProfile(
    userId: userId,
    name: name,
    photoUrl: url,
    categories: categories,
    experienceYears: experienceYears,
    skills: skills,
    rate: rate,
    unit: unit,
    city: city,
    available: available,
    verified: verified,
    ratingAvg: ratingAvg,
    ratingCount: ratingCount,
    completedJobs: completedJobs,
    bio: bio,
  );

  UserCard get card => UserCard(
    id: userId,
    name: name,
    photoUrl: photoUrl,
    verified: verified,
    ratingAvg: ratingAvg,
    ratingCount: ratingCount,
  );
}

class AssistantFilter {
  const AssistantFilter({
    this.query,
    this.category,
    this.city,
    this.maxRate,
    this.unit,
    this.minRating,
  });

  final String? query;
  final String? category;
  final String? city;
  final int? maxRate;
  final PeriodUnit? unit;
  final double? minRating;

  Map<String, dynamic> toQuery() => {
    'q': ?query,
    'category': ?category,
    'city': ?city,
    'max_rate': ?maxRate,
    'unit': ?unit?.name,
    'min_rating': ?minRating,
  };
}
