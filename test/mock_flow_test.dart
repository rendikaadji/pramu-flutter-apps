import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/mock/mock_flows.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/application/data/mock_application_repository.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/booking/data/mock_booking_repository.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/interview/data/mock_interview_repository.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/listing/data/mock_listing_repository.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/payment/data/mock_payment_repository.dart';
import 'package:pramu_apps/features/wallet/data/mock_wallet_repository.dart';

import 'helpers/memory_token_store.dart';

void main() {
  late DateTime clock;
  late MemoryTokenStore tokens;
  late MockBackend b;

  setUp(() {
    clock = DateTime.utc(2026, 10, 10, 3);
    tokens = MemoryTokenStore();
    b = MockBackend(tokens: tokens, clock: () => clock, latency: Duration.zero);
  });

  void loginAs(String name) =>
      tokens.write(MockBackend.tokenFor(b.userByName(name).id));

  Future<ApiException> failure(Future<Object?> f) async {
    try {
      await f;
    } on ApiException catch (e) {
      return e;
    }
    fail('seharusnya melempar ApiException');
  }

  test('alur penuh: wawancara -> kesepakatan -> bayar (cek status) -> konfirmasi -> dompet', () async {
    loginAs('Bu Rina');
    final apps = MockApplicationRepository(b);
    final interviews = MockInterviewRepository(b);
    final bookings = MockBookingRepository(b);
    final payments = MockPaymentRepository(b);

    final l1 = b.listings.values.firstWhere(
      (l) => l.title.startsWith('Pengasuh anak usia 3'),
    );
    final yuni = (await apps.forListing(l1.id))
        .firstWhere((a) => a.assistant.name == 'Yuni');
    expect(yuni.status, ApplicationStatus.shortlisted);

    // accept tanpa wawancara ditolak (lowongan tidak skip wawancara)
    expect(
      (await failure(apps.act(yuni.id, ApplicationAction.accept))).code,
      'APPLICATION_INVALID_STATE',
    );

    final iv = await interviews.propose(yuni.id, [
      clock.add(const Duration(days: 1)),
    ]);
    expect(
      (await interviews.get(iv.id)).status,
      InterviewStatus.confirmed,
    ); // Yuni (bot) konfirmasi
    await interviews.evaluate(
      iv.id,
      const InterviewEvaluation(
        communication: 5,
        politeness: 5,
        reliability: 4,
      ),
    );
    expect((await apps.get(yuni.id)).status, ApplicationStatus.interviewed);
    await apps.act(yuni.id, ApplicationAction.accept);

    final ag = await bookings.propose(
      yuni.id,
      AgreementInput(
        rate: 2000000,
        unit: PeriodUnit.monthly,
        periodCount: 3,
        startDate: clock.add(const Duration(days: 10)),
      ),
    );
    expect(ag.seekerApprovedAt, isNotNull);
    final agreed = await bookings.agreement(
      ag.id,
    ); // Yuni (bot) setuju saat dibaca
    expect(agreed.isAgreed, isTrue);
    final booking = await bookings.booking(agreed.bookingId!);
    expect(booking.periods, hasLength(3));
    final p1 = booking.periods.first;
    expect(
      (p1.status, p1.amount, p1.serviceFee, p1.total),
      (PeriodStatus.awaitingPayment, 2000000, 0, 2000000),
    );

    // bayar: paid hanya setelah cek status ke-2; kunci idempoten menghasilkan invoice sama
    final key = newIdempotencyKey();
    final inv = await payments.startPayment(p1.id, idempotencyKey: key);
    expect(
      (await payments.startPayment(p1.id, idempotencyKey: key)).id,
      inv.id,
    );
    expect(inv.amount, 2000000);
    expect(
      (await payments.checkStatus(p1.id)).status,
      PeriodStatus.awaitingPayment,
    );
    expect((await payments.checkStatus(p1.id)).status, PeriodStatus.paid);

    // waktu berjalan: paid -> in_progress -> awaiting_confirmation
    clock = clock.add(b.stepDelay);
    expect((await bookings.period(p1.id)).status, PeriodStatus.inProgress);
    clock = clock.add(b.stepDelay);
    expect(
      (await bookings.period(p1.id)).status,
      PeriodStatus.awaitingConfirmation,
    );

    final yuniBefore = b.balances[b.userByName('Yuni').id] ?? 0;
    expect(
      (await payments.confirmComplete(p1.id)).status,
      PeriodStatus.settled,
    );
    expect(b.balances[b.userByName('Yuni').id], yuniBefore + 1800000);
    expect(
      (await failure(payments.confirmComplete(p1.id))).code,
      'PERIOD_INVALID_STATE',
    );
  });

  test(
    'potongan 10% di sisi Pelamar: Pencari 1.000.000 -> Pelamar 900.000',
    () async {
      expect(b.net(1000000), 900000);
      expect(b.gross(900000), 1000000);

      loginAs('Bu Rina');
      final bookings = MockBookingRepository(b);
      final seeker = await bookings.previewFees(rate: 1000000, periodCount: 1);
      expect(
        (seeker.amount, seeker.seekerFee, seeker.seekerTotal),
        (1000000, 0, 1000000),
      );

      loginAs('Siti');
      final asst = await bookings.previewFees(rate: 900000, periodCount: 1);
      expect(
        (asst.amount, asst.assistantFee, asst.assistantReceives),
        (900000, 0, 900000),
      );
      final l = (await MockListingRepository(b).browse(const ListingFilter()))
          .items;
      final raw = b.listings[l.first.id]!;
      expect(l.first.budgetMin, b.net(raw.budgetMin));
    },
  );

  test('versi kesepakatan usang -> 409, counter menaikkan versi dan mereset persetujuan', () async {
    loginAs('Bu Rina');
    final apps = MockApplicationRepository(b);
    final bookings = MockBookingRepository(b);
    // lamar Siti ke lowongan Pak Agus -> bot bergerak 1 langkah per pembacaan
    loginAs('Siti');
    final l6 = b.listings.values.firstWhere((l) => l.owner.name == 'Pak Agus');
    final a4 = (await apps.mine()).firstWhere((a) => a.listingId == l6.id);
    // seed: wawancara I1 diajukan Pak Agus; Siti konfirmasi
    final interviews = MockInterviewRepository(b);
    final iv = await interviews.get(a4.interviewId!);
    await interviews.confirm(iv.id, iv.slots.first);
    for (var i = 0; i < 4; i++) {
      await apps.get(
        a4.id,
      ); // interviewScheduled -> interviewed -> accepted -> usulan kesepakatan
    }
    final ag = await bookings.byApplication(a4.id);
    expect(ag, isNotNull);
    expect(ag!.proposedBy.name, 'seeker');
    final countered = await bookings.counter(
      ag.id,
      AgreementInput(
        rate: 1900000,
        unit: ag.unit,
        periodCount: ag.periodCount,
        startDate: ag.startDate,
      ),
    );
    expect(countered.version, ag.version + 1);
    expect(countered.proposedBy.name, 'assistant');
    expect(
      (await failure(bookings.approve(ag.id, version: ag.version))).code,
      'AGREEMENT_VERSION_STALE',
    );
  });

  test(
    'slot menit :45 -> 502 MEET_CREATE_FAILED sekali, ulang berhasil',
    () async {
      loginAs('Bu Rina');
      final apps = MockApplicationRepository(b);
      final interviews = MockInterviewRepository(b);
      final l1 = b.listings.values.firstWhere(
        (l) => l.title.startsWith('Pengasuh anak usia 3'),
      );
      final ani = (await apps.forListing(l1.id))
          .firstWhere((a) => a.assistant.name == 'Ani');
      await apps.act(ani.id, ApplicationAction.shortlist);
      final iv = await interviews.propose(ani.id, [
        clock.add(const Duration(days: 1, minutes: 45)),
      ]);
      expect(
        (await interviews.get(iv.id)).status,
        InterviewStatus.proposed,
      ); // bot gagal, tetap proposed
      loginAs('Ani');
      expect(
        (await failure(interviews.confirm(iv.id, iv.slots.first))).code,
        'MEET_CREATE_FAILED',
      );
      expect(
        (await interviews.confirm(iv.id, iv.slots.first)).meetingUrl,
        kMockMeetUrl,
      );
    },
  );

  test('dompet: tarik dana idempoten, payout bergerak, 99.999 gagal dan saldo kembali', () async {
    loginAs('Siti');
    final wallet = MockWalletRepository(b);
    final before = (await wallet.wallet()).balance;
    expect(before, 1350000);
    final tx = await wallet.requestPayout(100000, idempotencyKey: 'k1');
    expect(
      (await wallet.requestPayout(100000, idempotencyKey: 'k1')).id,
      tx.id,
    );
    expect((await wallet.wallet()).balance, before - 100000);
    clock = clock.add(b.stepDelay * 2);
    final list = (await wallet.transactions()).items;
    expect(list.firstWhere((t) => t.id == tx.id).payoutStatus!.name, 'success');

    await wallet.requestPayout(99999, idempotencyKey: 'k2');
    final mid = (await wallet.wallet()).balance;
    clock = clock.add(b.stepDelay * 2);
    expect((await wallet.wallet()).balance, mid + 99999);
    expect(
      (await failure(wallet.requestPayout(5, idempotencyKey: 'k3'))).status,
      422,
    );
  });

  test(
    'booking seed Bu Rina + Ani otomatis dijeda karena tagihan lewat batas',
    () async {
      loginAs('Bu Rina');
      final list = await MockBookingRepository(b).bookings();
      expect(list.map((e) => e.status.name), containsAll(['active', 'paused']));
    },
  );
}
