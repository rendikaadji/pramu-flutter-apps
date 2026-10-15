import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';

enum InterviewAction { confirm, reschedule, join, cancel, evaluate }

enum InterviewStatus {
  proposed,
  confirmed,
  done,
  cancelled,
  noShow,
  unknown;

  static InterviewStatus from(String? s) => enumFromWire(values, s, unknown);

  String get label => switch (this) {
    proposed => 'Menunggu konfirmasi',
    confirmed => 'Terjadwal',
    done => 'Selesai',
    cancelled => 'Dibatalkan',
    noShow => 'Tidak hadir',
    unknown => 'Status tidak dikenal',
  };

  Set<InterviewAction> allowedActions(Role role) {
    final seeker = role == Role.seeker;
    return switch (this) {
      proposed =>
        seeker
            ? {InterviewAction.reschedule, InterviewAction.cancel}
            : {InterviewAction.confirm, InterviewAction.reschedule},
      confirmed => {
        InterviewAction.join,
        InterviewAction.reschedule,
        InterviewAction.cancel,
        if (seeker) InterviewAction.evaluate,
      },
      done => seeker ? {InterviewAction.evaluate} : const {},
      cancelled || noShow || unknown => const {},
    };
  }
}

class Interview {
  const Interview({
    required this.id,
    required this.applicationId,
    required this.slots,
    required this.status,
    this.confirmedSlot,
    this.meetingUrl,
    this.note,
  });

  factory Interview.fromJson(Map<String, dynamic> j) => Interview(
    id: j['id'] as String,
    applicationId: j['application_id'] as String,
    slots: [for (final s in j['slots'] as List) parseApiTime(s as String)],
    status: InterviewStatus.from(j['status'] as String?),
    confirmedSlot: j['confirmed_slot'] == null
        ? null
        : parseApiTime(j['confirmed_slot'] as String),
    meetingUrl: j['meeting_url'] as String?,
    note: j['note'] as String?,
  );

  final String id;
  final String applicationId;
  final List<DateTime> slots; // UTC
  final InterviewStatus status;
  final DateTime? confirmedSlot;

  /// Tampil hanya bila `isAllowedMeetingUrl` (https + meet.google.com).
  final String? meetingUrl;
  final String? note;

  Interview copyWith({
    List<DateTime>? slots,
    InterviewStatus? status,
    DateTime? confirmedSlot,
    String? meetingUrl,
  }) => Interview(
    id: id,
    applicationId: applicationId,
    slots: slots ?? this.slots,
    status: status ?? this.status,
    confirmedSlot: confirmedSlot ?? this.confirmedSlot,
    meetingUrl: meetingUrl ?? this.meetingUrl,
    note: note,
  );
}

/// Skor 1-5 per aspek; hanya terlihat pencari.
class InterviewEvaluation {
  const InterviewEvaluation({
    required this.communication,
    required this.politeness,
    required this.reliability,
    this.note,
  });

  factory InterviewEvaluation.fromJson(Map<String, dynamic> j) =>
      InterviewEvaluation(
        communication: j['communication'] as int,
        politeness: j['politeness'] as int,
        reliability: j['reliability'] as int,
        note: j['note'] as String?,
      );

  final int communication;
  final int politeness;
  final int reliability;
  final String? note;

  Map<String, dynamic> toJson() => {
    'communication': communication,
    'politeness': politeness,
    'reliability': reliability,
    'note': note,
  };
}
