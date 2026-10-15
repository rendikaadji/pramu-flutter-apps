import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/mock/mock_flows.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/interview/domain/interview_repository.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';

/// Slot dengan menit :45 -> konfirmasi pertama gagal 502 `MEET_CREATE_FAILED`, ulang berhasil.
class MockInterviewRepository implements InterviewRepository {
  MockInterviewRepository(this._b);
  final MockBackend _b;

  Application _appOf(Interview i) {
    final app = _b.applications[i.applicationId]!;
    final uid = _b.me.id;
    if (app.seeker.id != uid && app.assistant.id != uid) {
      apiFail(404, 'NOT_FOUND', 'Wawancara tidak ditemukan.');
    }
    return app;
  }

  Interview _party(String id) {
    final i =
        _b.interviews[id] ??
        apiFail(404, 'NOT_FOUND', 'Wawancara tidak ditemukan.');
    _appOf(i);
    _b.reactInterview(id);
    return _b.interviews[id]!;
  }

  void _checkSlots(List<DateTime> slots) {
    if (slots.isEmpty || slots.length > 3) {
      apiFail(422, 'VALIDATION_FAILED', 'Ajukan 1 sampai 3 slot.', {
        'slots': ['Ajukan 1 sampai 3 slot'],
      });
    }
    if (slots.any((s) => s.isBefore(_b.now()))) {
      apiFail(422, 'VALIDATION_FAILED', 'Slot tidak boleh di masa lalu.', {
        'slots': ['Slot tidak boleh di masa lalu'],
      });
    }
  }

  @override
  Future<Interview> propose(
    String applicationId,
    List<DateTime> slots, {
    String? note,
  }) => _b.run(() {
    final app = _b.applications[applicationId];
    if (app == null || app.seeker.id != _b.me.id) {
      apiFail(404, 'NOT_FOUND', 'Lamaran tidak ditemukan.');
    }
    if (app.status != ApplicationStatus.shortlisted) {
      apiFail(
        409,
        'APPLICATION_INVALID_STATE',
        'Status lamaran sudah berubah.',
      );
    }
    _checkSlots(slots);
    final old = _b.interviews[app.interviewId];
    if (old != null &&
        (old.status == InterviewStatus.proposed ||
            old.status == InterviewStatus.confirmed)) {
      apiFail(409, 'INTERVIEW_INVALID_STATE', 'Sudah ada wawancara aktif.');
    }
    final i = Interview(
      id: _b.newId(),
      applicationId: app.id,
      slots: slots,
      status: InterviewStatus.proposed,
      note: note,
    );
    _b.interviews[i.id] = i;
    _b.applications[app.id] = app.copyWith(interviewId: i.id);
    _b.notify(
      app.assistant.id,
      NotificationType.interview,
      'Jadwal wawancara diajukan',
      app.seeker.name,
      i.id,
    );
    return i;
  });

  @override
  Future<Interview> get(String id) => _b.run(() => _party(id));

  @override
  Future<Interview?> byApplication(String applicationId) => _b.run(() {
    final app =
        _b.applications[applicationId] ??
        apiFail(404, 'NOT_FOUND', 'Lamaran tidak ditemukan.');
    final id = app.interviewId;
    return id == null ? null : _party(id);
  });

  @override
  Future<Interview> confirm(String id, DateTime slot) => _b.run(() {
    final i = _party(id);
    if (_appOf(i).assistant.id != _b.me.id) {
      apiFail(403, 'FORBIDDEN', 'Hanya asisten yang dapat mengonfirmasi.');
    }
    return _b.confirmInterview(id, slot);
  });

  @override
  Future<Interview> reschedule(String id, List<DateTime> slots) => _b.run(() {
    final i = _party(id);
    final app = _appOf(i);
    if (i.status != InterviewStatus.proposed &&
        i.status != InterviewStatus.confirmed) {
      apiFail(
        409,
        'INTERVIEW_INVALID_STATE',
        'Status wawancara sudah berubah.',
      );
    }
    _checkSlots(slots);
    _b.applications[app.id] = app.copyWith(
      status: ApplicationStatus.shortlisted,
    );
    return _b.interviews[id] = Interview(
      id: i.id,
      applicationId: i.applicationId,
      slots: slots,
      status: InterviewStatus.proposed,
      note: i.note,
    );
  });

  @override
  Future<Interview> cancel(String id) => _b.run(() {
    final i = _party(id);
    final app = _appOf(i);
    if (i.status != InterviewStatus.proposed &&
        i.status != InterviewStatus.confirmed) {
      apiFail(
        409,
        'INTERVIEW_INVALID_STATE',
        'Status wawancara sudah berubah.',
      );
    }
    _b.applications[app.id] = app.copyWith(
      status: ApplicationStatus.shortlisted,
    );
    return _b.interviews[id] = i.copyWith(status: InterviewStatus.cancelled);
  });

  @override
  Future<void> evaluate(String id, InterviewEvaluation e) => _b.run(() {
    final i = _party(id);
    final app = _appOf(i);
    if (app.seeker.id != _b.me.id) {
      apiFail(403, 'FORBIDDEN', 'Hanya pencari yang dapat menilai.');
    }
    if (i.status != InterviewStatus.confirmed &&
        i.status != InterviewStatus.done) {
      apiFail(
        409,
        'INTERVIEW_INVALID_STATE',
        'Status wawancara sudah berubah.',
      );
    }
    if ([
      e.communication,
      e.politeness,
      e.reliability,
    ].any((s) => s < 1 || s > 5)) {
      apiFail(422, 'VALIDATION_FAILED', 'Skor harus 1 sampai 5.', {
        'scores': ['Skor harus 1 sampai 5'],
      });
    }
    _b.evaluations[id] = e;
    _b.interviews[id] = i.copyWith(status: InterviewStatus.done);
    if (app.status == ApplicationStatus.interviewScheduled) {
      _b.applications[app.id] = app.copyWith(
        status: ApplicationStatus.interviewed,
      );
    }
  });

  @override
  Future<InterviewEvaluation?> evaluation(String id) => _b.run(() {
    final i = _party(id);
    if (_appOf(i).seeker.id != _b.me.id) return null;
    return _b.evaluations[id];
  });
}
