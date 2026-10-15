import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';

enum ApplicationAction {
  shortlist,
  reject,
  proposeInterview,
  accept, // dari `shortlisted` hanya bila Listing.skipInterview
  withdraw,
  proposeAgreement,
}

enum ApplicationStatus {
  pending,
  shortlisted,
  interviewScheduled,
  interviewed,
  accepted,
  rejected,
  withdrawn,
  unknown;

  static ApplicationStatus from(String? s) => enumFromWire(values, s, unknown);

  String get label => switch (this) {
    pending => 'Dilamar',
    shortlisted => 'Masuk daftar pendek',
    interviewScheduled => 'Wawancara dijadwalkan',
    interviewed => 'Sudah diwawancara',
    accepted => 'Diterima',
    rejected => 'Tidak dipilih',
    withdrawn => 'Ditarik',
    unknown => 'Status tidak dikenal',
  };

  bool get isActive => this != rejected && this != withdrawn && this != unknown;

  /// Aksi yang boleh per peran (UIUX §9, M-37/M-45). Server tetap validasi (409).
  Set<ApplicationAction> allowedActions(Role role) {
    final seeker = role == Role.seeker;
    return switch (this) {
      pending =>
        seeker
            ? {ApplicationAction.shortlist, ApplicationAction.reject}
            : {ApplicationAction.withdraw},
      shortlisted =>
        seeker
            ? {
                ApplicationAction.proposeInterview,
                ApplicationAction.accept,
                ApplicationAction.reject,
              }
            : {ApplicationAction.withdraw},
      interviewScheduled =>
        seeker ? {ApplicationAction.reject} : {ApplicationAction.withdraw},
      interviewed =>
        seeker
            ? {ApplicationAction.accept, ApplicationAction.reject}
            : {ApplicationAction.withdraw},
      accepted => {ApplicationAction.proposeAgreement},
      rejected || withdrawn || unknown => const {},
    };
  }
}

class Application {
  const Application({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.seeker,
    required this.assistant,
    required this.message,
    required this.proposedRate,
    required this.status,
    required this.createdAt,
    this.answers = const [],
    this.skckVerified = false,
    this.conversationId,
    this.interviewId,
    this.agreementId,
    this.bookingId,
  });

  factory Application.fromJson(Map<String, dynamic> j) => Application(
    id: j['id'] as String,
    listingId: j['listing_id'] as String,
    listingTitle: j['listing_title'] as String,
    seeker: UserCard.fromJson(j['seeker'] as Map<String, dynamic>),
    assistant: UserCard.fromJson(j['assistant'] as Map<String, dynamic>),
    message: j['message'] as String? ?? '',
    proposedRate: j['proposed_rate'] as int,
    status: ApplicationStatus.from(j['status'] as String?),
    createdAt: parseApiTime(j['created_at'] as String),
    answers: List<String>.from(j['answers'] as List? ?? const []),
    skckVerified: j['skck_verified'] as bool? ?? false,
    conversationId: j['conversation_id'] as String?,
    interviewId: j['interview_id'] as String?,
    agreementId: j['agreement_id'] as String?,
    bookingId: j['booking_id'] as String?,
  );

  final String id;
  final String listingId;
  final String listingTitle;
  final UserCard seeker;
  final UserCard assistant;
  final String message;
  final int proposedRate; // rupiah
  final ApplicationStatus status;
  final DateTime createdAt;
  final List<String> answers; // hanya terlihat pencari
  final bool skckVerified;
  final String? conversationId;
  final String? interviewId;
  final String? agreementId;
  final String? bookingId;

  Application copyWith({
    ApplicationStatus? status,
    String? interviewId,
    String? agreementId,
    String? bookingId,
    int? proposedRate,
  }) => Application(
    id: id,
    listingId: listingId,
    listingTitle: listingTitle,
    seeker: seeker,
    assistant: assistant,
    message: message,
    proposedRate: proposedRate ?? this.proposedRate,
    status: status ?? this.status,
    createdAt: createdAt,
    answers: answers,
    skckVerified: skckVerified,
    conversationId: conversationId,
    interviewId: interviewId ?? this.interviewId,
    agreementId: agreementId ?? this.agreementId,
    bookingId: bookingId ?? this.bookingId,
  );
}

class ApplyInput {
  const ApplyInput({
    required this.message,
    required this.proposedRate,
    this.answers = const [],
  });

  final String message;
  final int proposedRate;
  final List<String> answers;

  Map<String, dynamic> toJson() => {
    'message': message,
    'proposed_rate': proposedRate,
    'answers': answers,
  };
}

class Invitation {
  const Invitation({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.seeker,
    required this.createdAt,
    this.message,
  });

  factory Invitation.fromJson(Map<String, dynamic> j) => Invitation(
    id: j['id'] as String,
    listingId: j['listing_id'] as String,
    listingTitle: j['listing_title'] as String,
    seeker: UserCard.fromJson(j['seeker'] as Map<String, dynamic>),
    createdAt: parseApiTime(j['created_at'] as String),
    message: j['message'] as String?,
  );

  final String id;
  final String listingId;
  final String listingTitle;
  final UserCard seeker;
  final DateTime createdAt;
  final String? message;
}
