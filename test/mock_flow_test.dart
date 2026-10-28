import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/mock/mock_flows.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/application/data/mock_application_repository.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/booking/data/mock_booking_repository.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/interview/data/mock_interview_repository.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';

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

  test(
    'alur penuh: wawancara -> kesepakatan -> kontrak berjalan -> selesai',
    () async {
      loginAs('Bu Rina');
      final apps = MockApplicationRepository(b);
      final interviews = MockInterviewRepository(b);
      final bookings = MockBookingRepository(b);

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
          periodCount: 2,
          startDate: clock.add(const Duration(days: 10)),
        ),
      );
      expect(ag.seekerApprovedAt, isNotNull);
      final agreed = await bookings.agreement(
        ag.id,
      ); // Yuni (bot) setuju saat dibaca
      expect(agreed.isAgreed, isTrue);
      final booking = await bookings.booking(agreed.bookingId!);
      expect(booking.periods, hasLength(2));
      final p1 = booking.periods.first;
      expect((p1.status, p1.amount), (PeriodStatus.scheduled, 2000000));

      // waktu berjalan: terjadwal -> berjalan -> selesai, tanpa pembayaran
      clock = clock.add(const Duration(days: 11));
      expect(
        (await bookings.booking(booking.id)).periods.first.status,
        PeriodStatus.inProgress,
      );
      clock = clock.add(const Duration(days: 70));
      final done = await bookings.booking(booking.id);
      expect(
        done.periods.every((p) => p.status == PeriodStatus.completed),
        isTrue,
      );
      expect(done.status, BookingStatus.completed);
    },
  );

  test(
    'batalkan kontrak: periode belum selesai ikut batal, batal ulang 409',
    () async {
      loginAs('Bu Rina');
      final bookings = MockBookingRepository(b);
      final list = await bookings.bookings();
      final active = list.firstWhere((x) => x.status == BookingStatus.active);
      final cancelled = await bookings.cancel(active.id, reason: 'Pindah kota');
      expect(cancelled.status, BookingStatus.cancelled);
      expect(cancelled.periods.every((p) => p.status.isFinal), isTrue);
      expect(
        (await failure(bookings.cancel(active.id, reason: 'lagi'))).code,
        'BOOKING_INVALID_STATE',
      );
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

  test('kontrak seed Bu Rina berjalan menurut jadwal', () async {
    loginAs('Bu Rina');
    final list = await MockBookingRepository(b).bookings();
    expect(list.map((e) => e.status.name), contains('active'));
  });
}
