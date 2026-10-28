import 'package:pramu_apps/features/auth/domain/auth.dart';

/// SEMUA path rute di sini (template `:id` untuk GoRoute, builder untuk navigasi).
/// Parameter `:id` selalu ULID; router menolak selain itu. Jangan taruh PII di path/query.
abstract final class Routes {
  // --- auth (M-01..06, M-24, M-26)
  static const welcome = '/welcome'; // M-01
  static const register = '/register'; // M-02
  static const otp = '/otp'; // M-03
  static const pickRole = '/onboarding/role'; // M-04
  static const login = '/login'; // M-05
  static const forgot = '/forgot'; // M-06
  static const account = '/account'; // M-24
  static const devices = '/account/devices'; // M-26

  // --- verification (M-10..16)
  static const verificationGate = '/verification'; // M-10
  static const verificationGuide = '/verification/guide'; // M-11
  static const verificationKtp = '/verification/ktp'; // M-12
  static const verificationSelfie = '/verification/selfie'; // M-13
  static const verificationReview = '/verification/review'; // M-14
  static const verificationStatus = '/verification/status'; // M-15
  static const skck = '/skck'; // M-16 (?listing=<ulid> opsional)

  // --- shell tab root
  static const seekerHome = '/s/home'; // M-20
  static const seekerSearch = '/s/search'; // M-30
  static const seekerJobs = '/s/jobs'; // M-35
  static const seekerChat = '/s/chat'; // M-60
  static const seekerAccount = '/s/profile'; // M-24 (tab Profil Pencari)
  static const assistantHome = '/a/home'; // M-21
  static const assistantListings = '/a/listings'; // M-41
  static const assistantJobs = '/a/jobs'; // M-44
  static const assistantChat = '/a/chat'; // M-60
  static const assistantAccount = '/a/profile'; // M-24 (tab Profil Pelamar)

  // --- notification / report umum
  static const notifications = '/notifications'; // M-23
  static const privacy = '/account/privacy'; // M-25
  static const profileEdit = '/profile/edit'; // M-40

  // --- template (GoRoute.path)
  static const assistantProfileT = '/assistants/:id'; // M-31
  static const inviteT = '/assistants/:id/invite'; // M-32
  static const listingNew = '/listings/new'; // M-33 (?draft=<ulid>)
  static const listingPayT = '/listings/:id/pay'; // M-34
  static const listingManageT = '/listings/:id/manage'; // M-36
  static const listingDetailT = '/listings/:id'; // M-42
  static const applyT = '/listings/:id/apply'; // M-43
  static const applicantT = '/applications/:id/applicant'; // M-37
  static const applicationDetailT = '/applications/:id'; // M-45
  static const interviewProposeT =
      '/applications/:id/interview/propose'; // M-50
  static const interviewConfirmT = '/interviews/:id/confirm'; // M-51
  static const interviewDetailT = '/interviews/:id'; // M-52
  static const interviewEvalT = '/interviews/:id/evaluation'; // M-53
  static const chatRoomT = '/chat/:id'; // M-61
  static const agreementNewT = '/applications/:id/agreement/new'; // M-70
  static const agreementReviewT = '/agreements/:id'; // M-71
  static const contracts = '/contracts'; // M-72
  static const bookingDetailT = '/bookings/:id'; // M-73
  static const bookingCancelT = '/bookings/:id/cancel'; // M-77
  static const payReturn =
      '/pay/return'; // ?listing=<ulid> -> M-34 (cek status biaya tayang)
  static const ratingT = '/bookings/:id/rating'; // M-90
  static const userReviewsT = '/users/:id/reviews'; // M-91
  static const reportNew =
      '/report/new'; // M-95 (?booking=&user=&conversation=)
  static const reportShareT = '/reports/:id/share'; // M-96
  static const reportStatusT = '/reports/:id'; // M-97

  // --- builder
  static String assistantProfile(String id) => '/assistants/$id';
  static String invite(String assistantId) => '/assistants/$assistantId/invite';
  static String listingPay(String id) => '/listings/$id/pay';
  static String listingManage(String id) => '/listings/$id/manage';
  static String listingDetail(String id) => '/listings/$id';
  static String apply(String listingId) => '/listings/$listingId/apply';
  static String applicant(String id) => '/applications/$id/applicant';
  static String applicationDetail(String id) => '/applications/$id';
  static String interviewPropose(String applicationId) =>
      '/applications/$applicationId/interview/propose';
  static String interviewConfirm(String id) => '/interviews/$id/confirm';
  static String interviewDetail(String id) => '/interviews/$id';
  static String interviewEval(String id) => '/interviews/$id/evaluation';
  static String chatRoom(String id) => '/chat/$id';
  static String agreementNew(String applicationId) =>
      '/applications/$applicationId/agreement/new';
  static String agreementReview(String id) => '/agreements/$id';
  static String bookingDetail(String id) => '/bookings/$id';
  static String bookingCancel(String id) => '/bookings/$id/cancel';
  static String rating(String bookingId) => '/bookings/$bookingId/rating';
  static String userReviews(String id) => '/users/$id/reviews';
  static String reportShare(String id) => '/reports/$id/share';
  static String reportStatus(String id) => '/reports/$id';

  static String home(Role role) =>
      role == Role.seeker ? seekerHome : assistantHome;

  /// Prefix peran untuk guard.
  static const seekerPrefix = '/s/';
  static const assistantPrefix = '/a/';

  /// Rute yang boleh diakses tanpa login.
  static const publicPaths = {welcome, register, otp, login, forgot};
}
