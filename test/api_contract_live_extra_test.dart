// Lanjutan uji kontrak live: endpoint yang tidak tercakup api_contract_live_test.dart
// (daftar+OTP, reset sandi, unggah berkas, perangkat, undangan, wawancara ulang/batal,
// ajukan balik kesepakatan, batal kontrak, rekening+tarik dana, bukti laporan).
// Jalankan setelah `php artisan migrate:fresh --seed` + `php artisan serve --port=8765`:
//   flutter test test/api_contract_live_extra_test.dart \
//     --dart-define=LIVE_API=true --dart-define=API_BASE_URL=http://127.0.0.1:8765/api/v1
import 'dart:convert';
import 'dart:io';

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
import 'package:pramu_apps/features/interview/data/api_interview_repository.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/listing/data/api_listing_repository.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/notification/data/api_notification_repository.dart';
import 'package:pramu_apps/features/payment/data/api_payment_repository.dart';
import 'package:pramu_apps/features/report/data/api_report_repository.dart';
import 'package:pramu_apps/features/report/domain/report.dart';
import 'package:pramu_apps/features/verification/data/api_verification_repository.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/features/wallet/data/api_wallet_repository.dart';
import 'package:pramu_apps/features/wallet/domain/wallet.dart';

import 'helpers/memory_token_store.dart';

const _live = bool.fromEnvironment('LIVE_API');

// PNG 1x1 valid (server memeriksa MIME asli).
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class _Session {
  _Session(this.label);
  final String label;
  final tokens = MemoryTokenStore();
  late final api = ApiClient(
    tokens: tokens,
    deviceId: 'extra-$label',
    onUnauthorized: () {},
  );
  late final auth = ApiAuthRepository(api);

  Future<AuthUser> login(String phone, [String pass = 'Rahasia123']) async {
    final s = await auth.login(identifier: phone, password: pass);
    await tokens.write(s.token);
    return s.user;
  }
}

void main() {
  late Directory tmp;
  late String img;

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('pramu_live_');
    img = '${tmp.path}/x.png';
    File(img).writeAsBytesSync(_png);
  });
  tearDownAll(() => tmp.deleteSync(recursive: true));

  test('daftar + OTP + peran + verifikasi KTP + reset sandi', () async {
    final s = _Session('new');
    final stamp = DateTime.now().millisecondsSinceEpoch % 100000000;
    final phone = '0812${stamp.toString().padLeft(8, '0')}';

    await s.auth.register(
      name: 'Uji Baru',
      phone: phone,
      email: 'baru$stamp@example.com',
      password: 'Rahasia123',
    );
    // login sebelum OTP diverifikasi ditolak
    await expectLater(
      s.auth.login(identifier: phone, password: 'Rahasia123'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'PHONE_NOT_VERIFIED')),
    );
    await expectLater(
      s.auth.verifyOtp(phone: phone, code: '000000'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'OTP_INVALID')),
    );
    await s.auth.sendOtp(phone);
    final session = await s.auth.verifyOtp(phone: phone, code: '123456');
    await s.tokens.write(session.token);
    expect(session.user.activeRole, isNull);

    final withRoles = await s.auth.setRoles({Role.seeker, Role.assistant});
    expect(withRoles.roles, {Role.seeker, Role.assistant});
    expect((await s.auth.switchRole(Role.assistant)).activeRole, Role.assistant);

    final ver = ApiVerificationRepository(s.api);
    expect((await ver.current()).status, VerificationStatus.none);
    final sent = await ver.submit(
      ktpPath: img,
      selfiePath: img,
      nik: '3273010101900009',
    );
    expect(sent.status, VerificationStatus.pending);
    await expectLater(
      ver.submit(ktpPath: img, selfiePath: img, nik: '3273010101900009'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'VERIFICATION_INVALID_STATE')),
    );
    // belum verified -> SKCK & pencarian ditolak
    await expectLater(
      ver.uploadSkck(img),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'VERIFICATION_REQUIRED')),
    );

    // reset sandi: semua token lama dicabut, login dengan sandi baru
    final other = _Session('new2');
    await other.auth.requestPasswordReset(phone);
    await other.auth.resetPassword(
      identifier: phone,
      code: '123456',
      newPassword: 'SandiBaru123',
    );
    await expectLater(s.auth.me(), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
    expect((await other.login(phone, 'SandiBaru123')).name, 'Uji Baru');
  });

  test('foto, SKCK, perangkat, push token (Bu Maya)', () async {
    final maya = _Session('maya');
    final other = _Session('maya-b');
    await maya.login('081355500002');
    await other.login('081355500002');

    final withPhoto = await maya.auth.uploadPhoto(img);
    expect(withPhoto.photoUrl, isNotNull);
    expect((await maya.auth.me()).photoUrl, isNotNull);
    await maya.auth.removePhoto();
    expect((await maya.auth.me()).photoUrl, isNull);

    final skck = await ApiVerificationRepository(maya.api).uploadSkck(img);
    expect(skck.status, VerificationStatus.pending);

    final notif = ApiNotificationRepository(maya.api);
    await notif.registerPushToken('fcm-live-token-1');
    await notif.unregisterPushToken('fcm-live-token-1');

    final devices = await maya.auth.devices();
    expect(devices.length, greaterThanOrEqualTo(2));
    final victim = devices.firstWhere((d) => !d.current);
    await maya.auth.revokeDevice(victim.id);
    expect((await maya.auth.devices()).any((d) => d.id == victim.id), isFalse);
    // token perangkat yang dicabut sudah tidak valid
    await expectLater(other.auth.me(), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
  });

  test('undangan Pencari -> Pelamar', () async {
    final rina = _Session('rina');
    final lestari = _Session('lestari');
    await rina.login('081234567890');
    await lestari.login('081311110003');

    final open = (await ApiListingRepository(rina.api).mine()).firstWhere(
      (l) => l.title == 'Pengasuh anak usia 3 tahun',
    );
    final lestariId = (await lestari.auth.me()).id;
    final apps = ApiApplicationRepository(rina.api);
    await apps.invite(assistantId: lestariId, listingId: open.id, message: 'Mari melamar');
    await expectLater(
      apps.invite(assistantId: lestariId, listingId: open.id),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'INVITATION_DUPLICATE')),
    );
    final inv = await ApiApplicationRepository(lestari.api).invitations();
    expect(inv.single.listingId, open.id);
    expect(inv.single.message, 'Mari melamar');
  });

  test('wawancara ulang/batal + ajukan balik kesepakatan + tanpa wawancara', () async {
    final siti = _Session('siti');
    final agus = _Session('agus');
    final hartini = _Session('hartini');
    await siti.login('081298765432');
    await agus.login('081311110012');
    await hartini.login('081311110011');

    // Wawancara seed (Pak Agus -> Siti): jadwal ulang lalu batal
    final myApps = await ApiApplicationRepository(siti.api).mine();
    final withIv = myApps.firstWhere((a) => a.interviewId != null);
    final iv = ApiInterviewRepository(siti.api);
    final base = DateTime.now().toUtc().add(const Duration(days: 4));
    final slot = DateTime.utc(base.year, base.month, base.day, 5);
    final re = await iv.reschedule(withIv.interviewId!, [slot]);
    expect(re.status, InterviewStatus.proposed);
    expect(re.slots.single, slot);
    expect(
      (await ApiInterviewRepository(agus.api).byApplication(withIv.id))?.id,
      withIv.interviewId,
    );
    expect((await iv.cancel(withIv.interviewId!)).status, InterviewStatus.cancelled);

    // Lowongan "ART mingguan" (lewati wawancara): lamar -> terima langsung
    final listings = await ApiListingRepository(siti.api).browse(const ListingFilter(category: 'Asisten Rumah Tangga'));
    final weekly = listings.items.firstWhere((l) => l.title == 'ART mingguan');
    expect(weekly.skipInterview, isTrue);
    final app = await ApiApplicationRepository(siti.api).apply(
      weekly.id,
      const ApplyInput(message: 'Siap bekerja', proposedRate: 450000),
    );
    final hApps = ApiApplicationRepository(hartini.api);
    await hApps.act(app.id, ApplicationAction.shortlist);
    await hApps.act(app.id, ApplicationAction.accept);

    // Pelamar usul, Pencari ajukan balik, Pelamar setuju versi terbaru -> kontrak
    final start = DateTime.now().add(const Duration(days: 12));
    final sBooking = ApiBookingRepository(siti.api);
    final hBooking = ApiBookingRepository(hartini.api);
    final ag = await sBooking.propose(
      app.id,
      AgreementInput(rate: 450000, unit: PeriodUnit.weekly, periodCount: 2, startDate: start),
    );
    expect(ag.proposedBy, Role.assistant);
    final countered = await hBooking.counter(
      ag.id,
      AgreementInput(rate: 520000, unit: PeriodUnit.weekly, periodCount: 3, startDate: start),
    );
    expect(countered.version, 2);
    expect(countered.proposedBy, Role.seeker);
    await expectLater(
      hBooking.approve(ag.id, version: 1),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'AGREEMENT_VERSION_STALE')),
    );
    final done = await sBooking.approve(ag.id, version: countered.version);
    expect(done.bookingId, isNotNull);
    final booking = await hBooking.booking(done.bookingId!);
    expect(booking.periods, hasLength(3));

    // Batal kontrak: pratinjau lalu batalkan (tidak ada dana dibayar -> refund 0)
    final pay = ApiPaymentRepository(hartini.api);
    final preview = await pay.cancelPreview(booking.id);
    expect(preview.refundToSeeker, 0);
    await expectLater(pay.cancel(booking.id, reason: ' '), throwsA(isA<ApiException>()));
    final cancelled = await pay.cancel(booking.id, reason: 'Rencana berubah');
    expect(cancelled.status, BookingStatus.cancelled);
    expect(cancelled.periods.every((p) => p.status == PeriodStatus.cancelled), isTrue);
  });

  test('rekening + tarik dana idempoten + bukti laporan', () async {
    final siti = _Session('siti2');
    final rina = _Session('rina2');
    final sitiUser = await siti.login('081298765432');
    await rina.login('081234567890');

    final wallet = ApiWalletRepository(siti.api);
    final bank = await wallet.saveBankAccount(bank: 'BNI', number: '9876543210', holderName: 'Siti N');
    expect(bank.maskedNumber, endsWith('3210'));
    expect((await wallet.bankAccount())?.bank, 'BNI');

    final before = (await wallet.wallet()).balance;
    final tx1 = await wallet.requestPayout(500000, idempotencyKey: 'live-payout-1');
    final tx2 = await wallet.requestPayout(500000, idempotencyKey: 'live-payout-1');
    expect(tx2.id, tx1.id);
    expect(tx1.type, WalletTxType.payout);
    expect(tx1.payoutStatus, PayoutStatus.queued);
    expect((await wallet.wallet()).balance, before - 500000);
    await expectLater(
      wallet.requestPayout(before * 2, idempotencyKey: 'live-payout-2'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 422)),
    );

    final reports = ApiReportRepository(rina.api);
    final report = await reports.submit(
      ReportInput(
        type: ReportType.behavior,
        description: 'Perilaku tidak sopan di percakapan.',
        userId: sitiUser.id,
        evidencePaths: [img],
      ),
    );
    expect(report.status, ReportStatus.received);
    expect((await reports.get(report.id)).id, report.id);
    expect((await reports.addEvidence(report.id, [img])).id, report.id);
    expect((await reports.mine()).any((r) => r.id == report.id), isTrue);
    // laporan milik orang lain tidak terlihat
    await expectLater(
      ApiReportRepository(siti.api).get(report.id),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
    );
  });
}
