// Uji kontrak terhadap backend pramu-web yang benar-benar jalan (bukan mock).
// Dilewati secara default. Jalankan setelah `php artisan migrate:fresh --seed` + `php artisan serve`:
//   flutter test test/api_contract_live_test.dart \
//     --dart-define=LIVE_API=true --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
// Env server yang diperlukan: OTP_FIXED_CODE=123456 (tanpa itu OTP acak). Tes live ini memakai data seed dan menulis ke DB, jadi
// jalankan `migrate:fresh --seed` sebelum tiap berkas dan jangan paralel (-j 1).
// Memastikan setiap Api*Repository + fromJson cocok dengan respons server asli.
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/application/data/api_application_repository.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/auth/data/api_auth_repository.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/data/api_booking_repository.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/chat/data/api_chat_repository.dart';
import 'package:pramu_apps/features/interview/data/api_interview_repository.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/listing/data/api_listing_repository.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/notification/data/api_notification_repository.dart';
import 'package:pramu_apps/features/profile/data/api_profile_repository.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';
import 'package:pramu_apps/features/rating/data/api_rating_repository.dart';
import 'package:pramu_apps/features/report/data/api_report_repository.dart';
import 'package:pramu_apps/features/report/domain/report.dart';
import 'package:pramu_apps/features/verification/data/api_verification_repository.dart';

import 'helpers/memory_token_store.dart';

const _live = bool.fromEnvironment('LIVE_API');

/// Klien per akun (token sendiri) agar dua pihak bisa diuji bergantian.
class _Session {
  _Session(this.label);
  final String label;
  final tokens = MemoryTokenStore();
  late final api = ApiClient(
    tokens: tokens,
    deviceId: 'contract-$label',
    onUnauthorized: () {},
  );

  Future<AuthUser> login(String phone) async {
    final s = await ApiAuthRepository(api)
        .login(identifier: phone, password: 'Rahasia123');
    await tokens.write(s.token);
    return s.user;
  }
}

void main() {
  test('kontrak API pramu-web cocok dengan Api*Repository', () async {
    final rina = _Session('rina');
    final siti = _Session('siti');
    final ani = _Session('ani');
    final rinaUser = await rina.login('081234567890');
    final sitiUser = await siti.login('081298765432');
    await ani.login('081311110002');
    expect(rinaUser.roles, contains(Role.seeker));
    expect(sitiUser.activeRole, Role.assistant);

    // Auth & perangkat
    final devices = await ApiAuthRepository(rina.api).devices();
    expect(devices.where((d) => d.current), hasLength(1));
    await expectLater(
      ApiAuthRepository(_Session('x').api)
          .login(identifier: '08999999999', password: 'Rahasia123'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'ACCOUNT_SUSPENDED'),
      ),
    );

    // Verifikasi
    expect(
      (await ApiVerificationRepository(siti.api).skck()).status.isVerified,
      isTrue,
    );

    // Lowongan: draft -> bayar -> tayang
    final listings = ApiListingRepository(rina.api);
    final draft = await listings.saveDraft(
      ListingInput(
        title: 'Uji kontrak juru masak',
        category: 'Juru Masak',
        description: 'Masak harian',
        city: 'Jakarta Selatan',
        unit: PeriodUnit.monthly,
        periodCount: 2,
        startDate: DateTime.now().add(const Duration(days: 10)),
        budgetMin: 2000000,
        budgetMax: 2500000,
      ),
    );
    expect(draft.status, ListingStatus.draft);
    final inv = await listings.pay(draft.id, idempotencyKey: 'contract-l1');
    expect(inv.amount, 25000);
    expect((await listings.get(draft.id)).status, ListingStatus.open);
    expect((await listings.mine()).length, greaterThan(1));

    // Pelamar melihat anggaran apa adanya
    final browse = await ApiListingRepository(siti.api)
        .browse(const ListingFilter(category: 'Juru Masak'));
    final seen = browse.items.firstWhere((l) => l.id == draft.id);
    expect(seen.budgetMin, 2000000);

    // Profil & pencarian
    final found = await ApiProfileRepository(rina.api)
        .search(const AssistantFilter(city: 'Jakarta Selatan'));
    expect(found.items, isNotEmpty);
    expect(
      (await ApiProfileRepository(siti.api).myProfile())?.userId,
      sitiUser.id,
    );

    // Lamaran -> shortlist -> wawancara -> evaluasi -> terima
    final app = await ApiApplicationRepository(siti.api).apply(
      draft.id,
      const ApplyInput(message: 'Saya siap', proposedRate: 1800000),
    );
    expect(app.proposedRate, 1800000);
    final rApps = ApiApplicationRepository(rina.api);
    expect((await rApps.forListing(draft.id)).single.proposedRate, 1800000);
    await rApps.act(app.id, ApplicationAction.shortlist);
    final slot = DateTime.now().toUtc().add(const Duration(days: 2));
    final iv = await ApiInterviewRepository(rina.api)
        .propose(app.id, [DateTime.utc(slot.year, slot.month, slot.day, 3)]);
    final confirmed = await ApiInterviewRepository(siti.api)
        .confirm(iv.id, iv.slots.first);
    expect(confirmed.status, InterviewStatus.confirmed);
    expect(confirmed.meetingUrl, startsWith('https://meet.google.com/'));
    await ApiInterviewRepository(rina.api).evaluate(
      iv.id,
      const InterviewEvaluation(
        communication: 5,
        politeness: 5,
        reliability: 4,
      ),
    );
    expect(
      (await ApiInterviewRepository(rina.api).evaluation(iv.id))?.reliability,
      4,
    );
    expect(await ApiInterviewRepository(siti.api).evaluation(iv.id), isNull);
    await rApps.act(app.id, ApplicationAction.accept);

    // Kesepakatan -> kontrak
    final rBooking = ApiBookingRepository(rina.api);
    final start = DateTime.now().add(const Duration(days: 10));
    final ag = await rBooking.propose(
      app.id,
      AgreementInput(
        rate: 2000000,
        unit: PeriodUnit.monthly,
        periodCount: 2,
        startDate: start,
      ),
    );
    final sBooking = ApiBookingRepository(siti.api);
    expect((await sBooking.byApplication(app.id))?.rate, 2000000);
    final agreed = await sBooking.approve(ag.id, version: ag.version);
    expect(agreed.bookingId, isNotNull);
    final booking = await rBooking.booking(agreed.bookingId!);
    expect(booking.periods, hasLength(2));
    expect((await sBooking.booking(booking.id)).rate, 2000000);
    expect(booking.periods.first.status, PeriodStatus.scheduled);

    // Kontrak jadi: chat terbuka
    final chat = ApiChatRepository(siti.api);
    final msg = await chat.send(app.id, 'WA saya 081298765432');
    expect(msg.masked, isFalse);
    expect(
      (await ApiChatRepository(
        rina.api,
      ).conversations()).any((c) => c.id == app.id),
      isTrue,
    );
    await ApiChatRepository(rina.api).markRead(app.id);

    // Rating, notifikasi
    expect(
      (await ApiRatingRepository(rina.api).reviewsOf(sitiUser.id)).items,
      isNotEmpty,
    );
    final notif = ApiNotificationRepository(siti.api);
    expect(await notif.unreadCount(), greaterThan(0));
    expect((await notif.list()).items.first.id, isNotEmpty);
    await notif.markAllRead();
    expect(await notif.unreadCount(), 0);

    // Laporan Pelamar terhadap kontrak Rina-Ani
    final aniBookings = await ApiBookingRepository(ani.api).bookings();
    final running = aniBookings.firstWhere(
      (b) => b.status == BookingStatus.active,
    );
    final report = await ApiReportRepository(ani.api).submit(
      ReportInput(
        type: ReportType.behavior,
        description: 'Pencari bersikap tidak pantas di chat.',
        bookingId: running.id,
      ),
    );
    expect(report.status, ReportStatus.received);
    final shared = await ApiReportRepository(ani.api)
        .shareConversation(report.id, conversationId: running.conversationId!);
    expect(shared.share?.revoked, isFalse);
    expect(
      (await ApiReportRepository(ani.api).revokeShare(report.id))
          .share
          ?.revoked,
      isTrue,
    );
  }, skip: _live ? false : 'Set --dart-define=LIVE_API=true');
}
