import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';

void main() {
  // status -> (canPay, canConfirmComplete, canDispute)
  final table = <PeriodStatus, (bool, bool, bool)>{
    PeriodStatus.awaitingPayment: (true, false, false),
    PeriodStatus.expired: (false, false, false),
    PeriodStatus.paid: (false, false, true),
    PeriodStatus.inProgress: (false, false, true),
    PeriodStatus.awaitingConfirmation: (false, true, true),
    PeriodStatus.completed: (false, false, false),
    PeriodStatus.settled: (false, false, false),
    PeriodStatus.cancelled: (false, false, false),
    PeriodStatus.disputed: (false, false, false),
    PeriodStatus.refunded: (false, false, false),
    PeriodStatus.unknown: (false, false, false),
  };

  test(
    'tabel mencakup semua PeriodStatus',
    () => expect(table.keys.toSet(), PeriodStatus.values.toSet()),
  );

  for (final e in table.entries) {
    test('period ${e.key.name}: pay/confirm/dispute', () {
      expect((
        e.key.canPay,
        e.key.canConfirmComplete,
        e.key.canDispute,
      ), e.value);
    });
  }

  test('aksi period per peran', () {
    expect(PeriodStatus.awaitingPayment.actionsFor(Role.seeker), {
      PeriodAction.pay,
    });
    expect(PeriodStatus.awaitingPayment.actionsFor(Role.assistant), isEmpty);
    expect(PeriodStatus.inProgress.actionsFor(Role.seeker), {
      PeriodAction.cancel,
      PeriodAction.report,
    });
    expect(PeriodStatus.inProgress.actionsFor(Role.assistant), {
      PeriodAction.report,
    });
    expect(PeriodStatus.awaitingConfirmation.actionsFor(Role.seeker), {
      PeriodAction.confirmComplete,
      PeriodAction.report,
    });
    expect(PeriodStatus.awaitingConfirmation.actionsFor(Role.assistant), {
      PeriodAction.report,
    });
    expect(PeriodStatus.disputed.actionsFor(Role.seeker), {
      PeriodAction.addEvidence,
    });
    expect(PeriodStatus.settled.actionsFor(Role.seeker), isEmpty);
  });

  test('label period per peran', () {
    expect(
      PeriodStatus.awaitingPayment.labelFor(Role.seeker),
      'Menunggu pembayaran Anda',
    );
    expect(
      PeriodStatus.awaitingPayment.labelFor(Role.assistant),
      'Menunggu pembayaran Pencari',
    );
    expect(
      PeriodStatus.from('status_baru').labelFor(Role.seeker),
      'Status tidak dikenal',
    );
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
