import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';

const kCategories = [
  'Asisten Rumah Tangga',
  'Pengasuh Anak',
  'Perawat Lansia',
  'Juru Masak',
  'Sopir Pribadi',
];

const kCities = [
  'Jakarta Selatan',
  'Jakarta Timur',
  'Jakarta Barat',
  'Bandung',
  'Surabaya',
  'Yogyakarta',
];

enum ListingStatus {
  draft,
  awaitingPayment,
  open,
  filled,
  closed,
  expired,
  unknown;

  static ListingStatus from(String? s) => enumFromWire(values, s, unknown);

  String get label => switch (this) {
    draft => 'Draf',
    awaitingPayment => 'Menunggu pembayaran',
    open => 'Tayang',
    filled => 'Terisi',
    closed => 'Ditutup',
    expired => 'Berakhir',
    unknown => 'Status tidak dikenal',
  };

  bool get canEdit => this == draft;
  bool get canPay => this == draft || this == awaitingPayment;
  bool get canClose => this == open;
  bool get acceptsApplications => this == open;
}

class Listing {
  const Listing({
    required this.id,
    required this.owner,
    required this.title,
    required this.category,
    required this.description,
    required this.city,
    required this.unit,
    required this.periodCount,
    required this.startDate,
    required this.budgetMin,
    required this.budgetMax,
    required this.status,
    required this.createdAt,
    this.requireSkck = false,
    this.skipInterview = false,
    this.screeningQuestions = const [],
    this.expiresAt,
    this.applicantCount = 0,
    this.postingFee = 25000,
    this.applied = false,
  });

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
    id: j['id'] as String,
    owner: UserCard.fromJson(j['owner'] as Map<String, dynamic>),
    title: j['title'] as String,
    category: j['category'] as String,
    description: j['description'] as String? ?? '',
    city: j['city'] as String,
    unit: PeriodUnit.from(j['period_unit'] as String?),
    periodCount: j['period_count'] as int,
    startDate: parseApiTime(j['start_date'] as String),
    budgetMin: j['budget_min'] as int,
    budgetMax: j['budget_max'] as int,
    status: ListingStatus.from(j['status'] as String?),
    createdAt: parseApiTime(j['created_at'] as String),
    requireSkck: j['require_skck'] as bool? ?? false,
    skipInterview: j['skip_interview'] as bool? ?? false,
    screeningQuestions: List<String>.from(
      j['screening_questions'] as List? ?? const [],
    ),
    expiresAt: j['expires_at'] == null
        ? null
        : parseApiTime(j['expires_at'] as String),
    applicantCount: j['applicant_count'] as int? ?? 0,
    postingFee: j['posting_fee'] as int? ?? 25000,
    applied: j['applied'] as bool? ?? false,
  );

  final String id;
  final UserCard owner;
  final String title;
  final String category;
  final String description;
  final String city;
  final PeriodUnit unit;
  final int periodCount;
  final DateTime startDate;
  final int budgetMin; // rupiah per periode
  final int budgetMax;
  final ListingStatus status;
  final DateTime createdAt;
  final bool requireSkck;
  final bool skipInterview;
  final List<String> screeningQuestions;
  final DateTime? expiresAt;
  final int applicantCount;
  final int postingFee; // angka dari server
  final bool applied; // tampilan asisten

  Listing copyWith({
    ListingStatus? status,
    int? applicantCount,
    DateTime? expiresAt,
  }) => Listing(
    id: id,
    owner: owner,
    title: title,
    category: category,
    description: description,
    city: city,
    unit: unit,
    periodCount: periodCount,
    startDate: startDate,
    budgetMin: budgetMin,
    budgetMax: budgetMax,
    status: status ?? this.status,
    createdAt: createdAt,
    requireSkck: requireSkck,
    skipInterview: skipInterview,
    screeningQuestions: screeningQuestions,
    expiresAt: expiresAt ?? this.expiresAt,
    applicantCount: applicantCount ?? this.applicantCount,
    postingFee: postingFee,
    applied: applied,
  );

  Listing withApplied(bool v) => Listing(
    id: id,
    owner: owner,
    title: title,
    category: category,
    description: description,
    city: city,
    unit: unit,
    periodCount: periodCount,
    startDate: startDate,
    budgetMin: budgetMin,
    budgetMax: budgetMax,
    status: status,
    createdAt: createdAt,
    requireSkck: requireSkck,
    skipInterview: skipInterview,
    screeningQuestions: screeningQuestions,
    expiresAt: expiresAt,
    applicantCount: applicantCount,
    postingFee: postingFee,
    applied: v,
  );
}

class ListingInput {
  const ListingInput({
    required this.title,
    required this.category,
    required this.description,
    required this.city,
    required this.unit,
    required this.periodCount,
    required this.startDate,
    required this.budgetMin,
    required this.budgetMax,
    this.requireSkck = false,
    this.skipInterview = false,
    this.screeningQuestions = const [],
  });

  final String title;
  final String category;
  final String description;
  final String city;
  final PeriodUnit unit;
  final int periodCount;
  final DateTime startDate;
  final int budgetMin;
  final int budgetMax;
  final bool requireSkck;
  final bool skipInterview;
  final List<String> screeningQuestions;

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'description': description,
    'city': city,
    'period_unit': unit.name,
    'period_count': periodCount,
    'start_date': toApiTime(startDate),
    'budget_min': budgetMin,
    'budget_max': budgetMax,
    'require_skck': requireSkck,
    'skip_interview': skipInterview,
    'screening_questions': screeningQuestions,
  };
}

class ListingFilter {
  const ListingFilter({
    this.query,
    this.category,
    this.city,
    this.maxBudget,
    this.unit,
  });

  final String? query;
  final String? category;
  final String? city;
  final int? maxBudget;
  final PeriodUnit? unit;

  Map<String, dynamic> toQuery() => {
    'q': ?query,
    'category': ?category,
    'city': ?city,
    'max_budget': ?maxBudget,
    'unit': ?unit?.name,
  };
}
