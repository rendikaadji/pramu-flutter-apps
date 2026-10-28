import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';

void main() {
  test('periode: hanya completed dan cancelled yang final', () {
    for (final st in PeriodStatus.values) {
      expect(
        st.isFinal,
        st == PeriodStatus.completed || st == PeriodStatus.cancelled,
        reason: st.name,
      );
    }
    expect(PeriodStatus.from('status_baru'), PeriodStatus.unknown);
    expect(PeriodStatus.scheduled.label, 'Terjadwal');
  });

  test('aksi lamaran per peran', () {
    expect(ApplicationStatus.pending.allowedActions(Role.seeker), {
      ApplicationAction.shortlist,
      ApplicationAction.reject,
    });
    expect(ApplicationStatus.pending.allowedActions(Role.assistant), {
      ApplicationAction.withdraw,
    });
    expect(ApplicationStatus.accepted.allowedActions(Role.assistant), {
      ApplicationAction.proposeAgreement,
    });
    expect(ApplicationStatus.rejected.allowedActions(Role.seeker), isEmpty);
    expect(ApplicationStatus.withdrawn.allowedActions(Role.assistant), isEmpty);
  });

  test('aksi wawancara: evaluasi hanya pencari', () {
    expect(
      InterviewStatus.confirmed.allowedActions(Role.seeker),
      contains(InterviewAction.evaluate),
    );
    expect(
      InterviewStatus.confirmed.allowedActions(Role.assistant),
      isNot(contains(InterviewAction.evaluate)),
    );
    expect(
      InterviewStatus.proposed.allowedActions(Role.assistant),
      contains(InterviewAction.confirm),
    );
    expect(
      InterviewStatus.proposed.allowedActions(Role.seeker),
      isNot(contains(InterviewAction.confirm)),
    );
  });
}
