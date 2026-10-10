import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';

const kMockMeetUrl = 'https://meet.google.com/abc-defg-hij';

/// Aturan alur lintas fitur + reaksi "pihak lawan otomatis" (pengguna `bot`).
/// Bot bereaksi satu langkah setiap kali entitas dibaca, supaya alur penuh bisa dicoba dengan 1 akun.
extension MockFlows on MockBackend {
  /// Slot dengan menit :45 gagal membuat Meet SEKALI per wawancara (502), percobaan ulang berhasil.
  Interview confirmInterview(String id, DateTime slot) {
    final i =
        interviews[id] ??
        apiFail(404, 'NOT_FOUND', 'Wawancara tidak ditemukan.');
    if (i.status != InterviewStatus.proposed) {
      apiFail(
        409,
        'INTERVIEW_INVALID_STATE',
        'Status wawancara sudah berubah.',
      );
    }
    if (!i.slots.contains(slot)) {
      apiFail(422, 'VALIDATION_FAILED', 'Slot tidak valid.', {
        'slot': ['Pilih salah satu slot yang diajukan'],
      });
    }
    if (slot.minute == 45 && meetFailed.add(id)) {
      apiFail(
        502,
        'MEET_CREATE_FAILED',
        'Tautan wawancara belum dapat dibuat. Lamaran Anda aman. Coba lagi.',
      );
    }
    final done = i.copyWith(
      status: InterviewStatus.confirmed,
      confirmedSlot: slot,
      meetingUrl: kMockMeetUrl,
    );
    interviews[id] = done;
    final app = applications[i.applicationId]!;
    applications[app.id] = app.copyWith(
      status: ApplicationStatus.interviewScheduled,
    );
    notify(
      app.seeker.id,
      NotificationType.interview,
      'Wawancara dikonfirmasi',
      '${app.assistant.name} memilih jadwal.',
      id,
    );
    return done;
  }

  /// Setuju; bila kedua pihak sudah setuju, booking dibuat.
  Agreement approveAgreement(Agreement a, Role r) {
    final t = now();
    var next = r == Role.seeker
        ? a.copyWith(seekerApprovedAt: t)
        : a.copyWith(assistantApprovedAt: t);
    if (next.isAgreed) next = next.copyWith(bookingId: createBooking(next).id);
    agreements[a.id] = next;
    return next;
  }

  void reactApplication(String id) {
    final app = applications[id];
    if (app == null || !users[app.seeker.id]!.bot) return;
    final l = listings[app.listingId]!;
    switch (app.status) {
      case ApplicationStatus.pending:
        applications[id] = app.copyWith(status: ApplicationStatus.shortlisted);
        notify(
          app.assistant.id,
          NotificationType.application,
          'Lamaran masuk daftar pendek',
          app.listingTitle,
          id,
        );
      case ApplicationStatus.shortlisted:
        if (l.skipInterview) {
          applications[id] = app.copyWith(status: ApplicationStatus.accepted);
        } else if (app.interviewId == null) {
          final slot = DateTime.utc(
            now().year,
            now().month,
            now().day,
            3,
          ).add(const Duration(days: 2));
          final i = Interview(
            id: newId(),
            applicationId: id,
            slots: [slot],
            status: InterviewStatus.proposed,
          );
          interviews[i.id] = i;
          applications[id] = app.copyWith(interviewId: i.id);
          notify(
            app.assistant.id,
            NotificationType.interview,
            'Jadwal wawancara diajukan',
            app.seeker.name,
            i.id,
          );
        }
      case ApplicationStatus.interviewScheduled:
        final i = interviews[app.interviewId];
        if (i != null) {
          interviews[i.id] = i.copyWith(status: InterviewStatus.done);
        }
        applications[id] = app.copyWith(status: ApplicationStatus.interviewed);
      case ApplicationStatus.interviewed:
        applications[id] = app.copyWith(status: ApplicationStatus.accepted);
        notify(
          app.assistant.id,
          NotificationType.application,
          'Lamaran diterima',
          app.listingTitle,
          id,
        );
      case ApplicationStatus.accepted:
        if (app.agreementId == null) {
          final start = l.startDate;
          final a = Agreement(
            id: newId(),
            applicationId: id,
            version: 1,
            rate: app.proposedRate,
            unit: l.unit,
            periodCount: l.periodCount,
            startDate: start,
            proposedBy: Role.seeker,
            fees: feesFor(app.proposedRate * l.periodCount),
            seekerApprovedAt: now(),
          );
          agreements[a.id] = a;
          applications[id] = app.copyWith(agreementId: a.id);
          notify(
            app.assistant.id,
            NotificationType.agreement,
            'Usulan kesepakatan',
            app.listingTitle,
            a.id,
          );
        }
      default:
    }
  }

  /// Pihak lawan bot langsung menyetujui usulan terbaru.
  void reactAgreement(String id) {
    final a = agreements[id];
    if (a == null || a.isAgreed) return;
    final app = applications[a.applicationId]!;
    for (final r in Role.values) {
      final uid = r == Role.seeker ? app.seeker.id : app.assistant.id;
      final fresh = agreements[id]!;
      if (users[uid]!.bot && !fresh.approvedBy(r)) approveAgreement(fresh, r);
    }
  }

  /// Asisten bot langsung mengonfirmasi slot pertama.
  void reactInterview(String id) {
    final i = interviews[id];
    if (i == null || i.status != InterviewStatus.proposed) return;
    final app = applications[i.applicationId]!;
    // bot tidak mengonfirmasi slot :45 supaya skenario 502 bisa diuji manual
    if (users[app.assistant.id]!.bot && i.slots.first.minute != 45) {
      confirmInterview(id, i.slots.first);
    }
  }
}
