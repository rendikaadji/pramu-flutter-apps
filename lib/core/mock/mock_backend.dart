import 'dart:math';

import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/storage/secure_token_store.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/chat/domain/chat.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';
import 'package:pramu_apps/features/rating/domain/rating.dart';
import 'package:pramu_apps/features/report/domain/report.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/features/wallet/domain/wallet.dart';

const kMockPassword = 'Rahasia123';
const kMockOtpOk = '123456';

Never apiFail(
  int status,
  String code,
  String message, [
  Map<String, List<String>> fields = const {},
]) => throw ApiException(
  status: status,
  code: code,
  message: message,
  fields: fields,
);

class MockUser {
  MockUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    Set<Role>? roles,
    this.activeRole,
    this.verification = VerificationStatus.none,
    this.bot = false,
    this.suspended = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.completedJobs = 0,
  }) : roles = roles ?? {};

  final String id;
  final String name;
  final String phone;
  final String email;
  String password;
  Set<Role> roles;
  Role? activeRole;
  VerificationStatus verification;
  String? photoUrl;
  String? rejectReason;
  bool phoneVerified = true;
  final bool
  bot; // pihak lawan otomatis (setuju/konfirmasi/shortlist saat data dibaca)
  final bool suspended;
  double ratingAvg;
  int ratingCount;
  int completedJobs;
  Verification skck = const Verification();
  int verificationPolls = 0;
}

class MockConversation {
  MockConversation(
    this.id,
    this.applicationId,
    this.seekerId,
    this.assistantId, [
    this.bookingId,
  ]);
  final String id;
  final String applicationId;
  final String seekerId;
  final String assistantId;
  String? bookingId;
}

class MockReview {
  MockReview(this.review, this.reviewerId, this.revieweeId);
  final Review review;
  final String reviewerId;
  final String revieweeId;
}

class MockInvoice {
  MockInvoice(this.id, this.kind, this.targetId, this.amount);
  final String id;
  final String kind; // 'listing' | 'period'
  final String targetId;
  final int amount;
  int checks = 0;
}

/// Satu penyimpanan in-memory bersama semua `Mock*Repository`, agar entitas konsisten lintas fitur.
/// Mensimulasikan server: validasi, state machine, error envelope. Bukan untuk produksi.
class MockBackend {
  MockBackend({
    required this._tokens,
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 150),
  }) : now = clock ?? DateTime.now {
    _seed();
  }

  final TokenStore _tokens;
  DateTime Function() now;
  Duration latency;

  /// Jeda antar langkah otomatis: paid -> in_progress -> awaiting_confirmation, payout queued -> processing -> success.
  Duration stepDelay = const Duration(seconds: 15);

  final users = <String, MockUser>{};
  final profiles = <String, AssistantProfile>{};
  final listings = <String, Listing>{};
  final applications = <String, Application>{};
  final invitations = <(String, Invitation)>[]; // (assistantId, undangan)
  final interviews = <String, Interview>{};
  final evaluations = <String, InterviewEvaluation>{};
  final conversations = <String, MockConversation>{};
  final messages = <String, List<ChatMessage>>{};
  final agreements = <String, Agreement>{};
  final bookings = <String, Booking>{};
  final bookingPeriods = <String, List<String>>{};
  final periods = <String, BookingPeriod>{};
  final completedAt = <String, DateTime>{};
  final balances = <String, int>{};
  final walletTx = <String, List<WalletTx>>{};
  final banks = <String, (String, String, String)>{};
  final payoutByKey = <String, WalletTx>{};
  final payoutStart = <String, DateTime>{};
  final reviews = <MockReview>[];
  final notifications = <String, List<AppNotification>>{};
  final reports = <String, (String, Report)>{}; // id -> (ownerId, report)
  final invoices = <String, MockInvoice>{};
  final invoiceByKey = <String, String>{};
  final otpFails = <String, int>{};
  final meetFailed = <String>{};
  final devices = <String, List<Device>>{};
  final pushTokens = <String>{};

  // ------------------------------------------------------------------ util

  Future<T> run<T>(T Function() body) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return body();
  }

  String newId() => ulid(at: now());

  Paged<T> page<T>(List<T> all, String? cursor, {int size = 10}) {
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = min(start + size, all.length);
    return Paged(
      all.sublist(start, end),
      nextCursor: end < all.length ? '$end' : null,
    );
  }

  static String tokenFor(String userId) => 'mock.$userId';

  String? get currentUserId {
    final t = _tokens.cached;
    return t != null &&
            t.startsWith('mock.') &&
            users.containsKey(t.substring(5))
        ? t.substring(5)
        : null;
  }

  /// Pengguna aktif; 401 bila token tidak ada/tidak dikenal.
  MockUser get me {
    final id = currentUserId;
    if (id == null) {
      apiFail(
        401,
        'UNAUTHENTICATED',
        'Sesi Anda berakhir. Silakan masuk lagi.',
      );
    }
    return users[id]!;
  }

  Role get role =>
      me.activeRole ??
      apiFail(409, 'ROLE_REQUIRED', 'Pilih peran Anda dulu untuk melanjutkan.');

  MockUser userByName(String name) =>
      users.values.firstWhere((u) => u.name == name);

  UserCard card(String userId) {
    final u = users[userId]!;
    return UserCard(
      id: u.id,
      name: u.name,
      verified: u.verification.isVerified,
      ratingAvg: u.ratingAvg,
      ratingCount: u.ratingCount,
    );
  }

  void requireVerified() {
    if (!me.verification.isVerified) {
      apiFail(
        403,
        'VERIFICATION_REQUIRED',
        'Verifikasi identitas Anda dulu untuk melanjutkan.',
      );
    }
  }

  void notify(
    String userId,
    NotificationType type,
    String title,
    String body,
    String? targetId,
  ) {
    (notifications[userId] ??= []).insert(
      0,
      AppNotification(
        id: newId(),
        type: type,
        title: title,
        body: body,
        createdAt: now(),
        targetId: targetId,
      ),
    );
  }

  /// Penyamaran ala server: nomor HP dan email diganti sampai booking dibayar.
  static String maskContacts(String text) => text
      .replaceAll(RegExp(r'(\+?62|0)8[\d\s-]{8,14}'), '[nomor disembunyikan]')
      .replaceAll(RegExp(r'[^@\s]+@[^@\s]+\.[^@\s]+'), '[email disembunyikan]');

  /// Potongan platform: 10% penuh dari sisi Pelamar, Pencari membayar sesuai
  /// nominal yang diinput (tanpa biaya tambahan). Angka tersimpan = nominal Pencari.
  static const _feePercent = 10;

  Fees feesFor(int amount) {
    final fee = amount * _feePercent ~/ 100;
    return Fees(
      amount: amount,
      seekerFee: 0,
      seekerTotal: amount,
      assistantFee: fee,
      assistantReceives: amount - fee,
    );
  }

  // ---- tampilan per pihak (meniru server): Pelamar hanya melihat nominal
  // bersih, tanpa tahu ada potongan. Data internal tetap nominal Pencari.

  /// Nominal Pencari -> yang tampil di Pelamar.
  int net(int gross) => gross - gross * _feePercent ~/ 100;

  /// Nominal yang diinput Pelamar (bersih) -> nominal Pencari (dibulatkan ke atas).
  int gross(int net) =>
      (net * 100 + (100 - _feePercent) - 1) ~/ (100 - _feePercent);

  /// Peran aktif pemanggil = asisten (untuk layar yang tak punya pihak kontrak).
  bool get viewerIsAssistant {
    final id = currentUserId;
    return id != null && users[id]?.activeRole == Role.assistant;
  }

  int amountFor(int gross, {required bool asAssistant}) =>
      asAssistant ? net(gross) : gross;

  int amountFrom(int shown, {required bool asAssistant}) =>
      asAssistant ? gross(shown) : shown;

  Fees viewFees(Fees f, {required bool asAssistant}) {
    if (!asAssistant) return f;
    final n = net(f.amount);
    return Fees(
      amount: n,
      seekerFee: 0,
      seekerTotal: n,
      assistantFee: 0,
      assistantReceives: n,
    );
  }

  Listing listingFor(Listing l, {required bool asAssistant}) => asAssistant
      ? l.copyWith(budgetMin: net(l.budgetMin), budgetMax: net(l.budgetMax))
      : l;

  Application applicationFor(Application a, {required bool asAssistant}) =>
      asAssistant ? a.copyWith(proposedRate: net(a.proposedRate)) : a;

  Agreement agreementFor(Agreement a, {required bool asAssistant}) =>
      asAssistant
      ? a.copyWith(rate: net(a.rate), fees: viewFees(a.fees, asAssistant: true))
      : a;

  BookingPeriod periodFor(BookingPeriod p, {required bool asAssistant}) =>
      asAssistant
      ? p.copyWith(amount: net(p.amount), serviceFee: 0, total: net(p.amount))
      : p;

  Booking bookingFor(Booking b, {required bool asAssistant}) => asAssistant
      ? b.copyWith(
          rate: net(b.rate),
          fees: viewFees(b.fees, asAssistant: true),
          periods: [for (final p in b.periods) periodFor(p, asAssistant: true)],
        )
      : b;

  // ------------------------------------------------------- cross-feature flow

  /// Kedua pihak setuju -> booking + period dibuat, lowongan terisi.
  Booking createBooking(Agreement a) {
    final app = applications[a.applicationId]!;
    final id = newId();
    final ids = <String>[];
    for (var i = 0; i < a.periodCount; i++) {
      final start = a.startDate.add(a.unit.duration * i);
      final p = BookingPeriod(
        id: newId(),
        bookingId: id,
        index: i + 1,
        start: start,
        end: start.add(a.unit.duration),
        amount: a.rate,
        serviceFee: 0,
        total: a.rate,
        status: PeriodStatus.awaitingPayment,
        dueAt: start.subtract(const Duration(days: 3)),
      );
      periods[p.id] = p;
      ids.add(p.id);
    }
    bookingPeriods[id] = ids;
    final b = Booking(
      id: id,
      applicationId: app.id,
      listingTitle: app.listingTitle,
      seeker: app.seeker,
      assistant: app.assistant,
      rate: a.rate,
      unit: a.unit,
      periodCount: a.periodCount,
      startDate: a.startDate,
      status: BookingStatus.active,
      fees: feesFor(a.rate * a.periodCount),
      periods: const [],
      conversationId: app.conversationId,
    );
    bookings[id] = b;
    applications[app.id] = app.copyWith(bookingId: id);
    final l = listings[app.listingId];
    if (l != null) listings[l.id] = l.copyWith(status: ListingStatus.filled);
    final conv = conversations[app.conversationId];
    conv?.bookingId = id;
    for (final uid in [app.seeker.id, app.assistant.id]) {
      notify(
        uid,
        NotificationType.booking,
        'Kontrak dimulai',
        app.listingTitle,
        id,
      );
    }
    return b;
  }

  /// Booking dengan period terbaru (menjalankan langkah otomatis berbasis waktu).
  Booking booking(String id) {
    final b =
        bookings[id] ??
        apiFail(
          404,
          'NOT_FOUND',
          'Kontrak tidak ditemukan. Mungkin sudah dihapus.',
        );
    final uid = currentUserId;
    if (uid != null && b.seeker.id != uid && b.assistant.id != uid) {
      apiFail(
        404,
        'NOT_FOUND',
        'Kontrak tidak ditemukan. Mungkin sudah dihapus.',
      );
    }
    _advance(b);
    return bookings[id]!.copyWith(
      periods: [for (final pid in bookingPeriods[id]!) periods[pid]!],
    );
  }

  void _advance(Booking b) {
    final t = now();
    for (final pid in bookingPeriods[b.id]!) {
      var p = periods[pid]!;
      final paid = p.paidAt;
      if (p.status == PeriodStatus.paid &&
          paid != null &&
          t.difference(paid) >= stepDelay) {
        p = p.copyWith(status: PeriodStatus.inProgress);
      }
      if (p.status == PeriodStatus.inProgress &&
          paid != null &&
          t.difference(paid) >= stepDelay * 2) {
        p = p.copyWith(
          status: PeriodStatus.awaitingConfirmation,
          autoReleaseAt: t.add(const Duration(hours: 24)),
        );
      }
      periods[pid] = p;
      final release = p.autoReleaseAt;
      if (p.status == PeriodStatus.awaitingConfirmation &&
          release != null &&
          !t.isBefore(release)) {
        settle(pid);
      }
    }
    final current = bookings[b.id]!;
    if (current.status != BookingStatus.active &&
        current.status != BookingStatus.paused) {
      return;
    }
    final overdue = [
      for (final pid in bookingPeriods[b.id]!)
        if (periods[pid]!.status == PeriodStatus.awaitingPayment &&
            periods[pid]!.dueAt.isBefore(t))
          periods[pid]!,
    ];
    if (overdue.isNotEmpty && current.status == BookingStatus.active) {
      bookings[b.id] = current.copyWith(
        status: BookingStatus.paused,
        pausedUntil: overdue.first.dueAt.add(const Duration(days: 7)),
      );
    } else if (overdue.isEmpty && current.status == BookingStatus.paused) {
      bookings[b.id] = current.copyWith(
        status: BookingStatus.active,
        clearPausedUntil: true,
      );
    }
  }

  /// Dana period dicairkan ke dompet pelamar; kontrak selesai bila semua period final.
  void settle(String periodId) {
    final p = periods[periodId]!;
    periods[periodId] = p.copyWith(status: PeriodStatus.settled);
    final b = bookings[p.bookingId]!;
    final receives = feesFor(p.amount).assistantReceives;
    final aid = b.assistant.id;
    balances[aid] = (balances[aid] ?? 0) + receives;
    (walletTx[aid] ??= []).insert(
      0,
      WalletTx(
        id: newId(),
        type: WalletTxType.earning,
        amount: receives,
        title: '${b.listingTitle} - periode ${p.index}',
        createdAt: now(),
      ),
    );
    notify(
      aid,
      NotificationType.payment,
      'Dana dicairkan',
      'Dana sudah masuk ke dompet Anda.',
      p.id,
    );
    final all = bookingPeriods[b.id]!.map((id) => periods[id]!);
    if (all.every((e) => e.status.isFinal) &&
        b.status != BookingStatus.completed) {
      bookings[b.id] = b.copyWith(status: BookingStatus.completed);
      completedAt[b.id] = now();
      final u = users[aid]!;
      u.completedJobs++;
      for (final (reviewer, reviewee) in [
        (aid, b.seeker.id),
        (b.seeker.id, aid),
      ]) {
        if (users[reviewer]!.bot) {
          reviews.add(
            MockReview(
              Review(
                id: newId(),
                bookingId: b.id,
                reviewerName: users[reviewer]!.name,
                stars: 5,
                comment: 'Kerja samanya lancar. Terima kasih.',
                createdAt: now(),
              ),
              reviewer,
              reviewee,
            ),
          );
        }
      }
      for (final uid in [b.seeker.id, aid]) {
        notify(
          uid,
          NotificationType.rating,
          'Beri penilaian',
          'Kontrak selesai. Beri penilaian dalam 7 hari.',
          b.id,
        );
      }
    }
  }

  // ------------------------------------------------------------------- seed

  late final Random _rnd = Random(7);
  String _sid() => ulid(at: DateTime.utc(2026, 10, 1), random: _rnd);

  MockUser _user(
    String name,
    String phone,
    Set<Role> roles, {
    bool bot = false,
    bool verified = true,
    bool suspended = false,
    double rating = 0,
    int ratingCount = 0,
    int jobs = 0,
  }) {
    final u = MockUser(
      id: _sid(),
      name: name,
      phone: normalizePhone(phone),
      email: '${name.split(' ').last.toLowerCase()}@example.com',
      password: kMockPassword,
      roles: roles,
      activeRole: roles.isEmpty ? null : roles.first,
      verification: verified
          ? VerificationStatus.verified
          : VerificationStatus.none,
      bot: bot,
      suspended: suspended,
      ratingAvg: rating,
      ratingCount: ratingCount,
      completedJobs: jobs,
    );
    users[u.id] = u;
    devices[u.id] = [
      Device(
        id: _sid(),
        name: 'Perangkat ini',
        lastActiveAt: now(),
        current: true,
      ),
    ];
    return u;
  }

  void _profile(
    MockUser u,
    List<String> cats,
    int exp,
    List<String> skills,
    int rate,
    PeriodUnit unit,
    String city,
    String bio,
  ) {
    profiles[u.id] = AssistantProfile(
      userId: u.id,
      name: u.name,
      categories: cats,
      experienceYears: exp,
      skills: skills,
      rate: rate,
      unit: unit,
      city: city,
      verified: u.verification.isVerified,
      ratingAvg: u.ratingAvg,
      ratingCount: u.ratingCount,
      completedJobs: u.completedJobs,
      bio: bio,
    );
  }

  Listing _listing(
    MockUser owner,
    String title,
    String category,
    String city,
    ListingStatus status,
    int min,
    int max,
    PeriodUnit unit,
    int count, {
    bool skck = false,
    bool skip = false,
    int applicants = 0,
  }) {
    final t = now();
    final l = Listing(
      id: _sid(),
      owner: card(owner.id),
      title: title,
      category: category,
      description:
          'Mencari $title. Lingkungan nyaman, jam kerja jelas, dan kebutuhan dibicarakan sejak awal.',
      city: city,
      unit: unit,
      periodCount: count,
      startDate: t.add(const Duration(days: 14)),
      budgetMin: min,
      budgetMax: max,
      status: status,
      createdAt: t.subtract(const Duration(days: 3)),
      requireSkck: skck,
      skipInterview: skip,
      screeningQuestions: const [
        'Apakah Anda bersedia bekerja di akhir pekan?',
      ],
      expiresAt: status == ListingStatus.open
          ? t.add(const Duration(days: 27))
          : null,
      applicantCount: applicants,
    );
    listings[l.id] = l;
    return l;
  }

  Application _application(
    Listing l,
    MockUser assistant,
    ApplicationStatus status,
    int rate,
    String msg,
  ) {
    final convId = _sid();
    final app = Application(
      id: _sid(),
      listingId: l.id,
      listingTitle: l.title,
      seeker: l.owner,
      assistant: card(assistant.id),
      message: msg,
      proposedRate: rate,
      status: status,
      createdAt: now().subtract(const Duration(days: 2)),
      answers: const ['Bersedia.'],
      skckVerified: assistant.skck.status.isVerified,
      conversationId: convId,
    );
    applications[app.id] = app;
    conversations[convId] = MockConversation(
      convId,
      app.id,
      l.owner.id,
      assistant.id,
    );
    messages[convId] = [
      ChatMessage(
        id: _sid(),
        conversationId: convId,
        senderId: assistant.id,
        text: 'Selamat siang, saya tertarik dengan lowongan ini.',
        createdAt: now().subtract(const Duration(days: 2)),
        readAt: now().subtract(const Duration(days: 1)),
      ),
      ChatMessage(
        id: _sid(),
        conversationId: convId,
        senderId: l.owner.id,
        text: 'Terima kasih sudah melamar. Mari kita bicarakan lebih lanjut.',
        createdAt: now().subtract(const Duration(days: 1)),
      ),
    ];
    return app;
  }

  /// Kontrak berjalan hasil lamaran `accepted` + kesepakatan disetujui kedua pihak.
  void _booking(
    Application app,
    int rate,
    PeriodUnit unit,
    List<PeriodStatus> statuses,
    Duration startOffset,
  ) {
    final t = now();
    final ag = Agreement(
      id: _sid(),
      applicationId: app.id,
      version: 1,
      rate: rate,
      unit: unit,
      periodCount: statuses.length,
      startDate: t.add(startOffset),
      proposedBy: Role.seeker,
      fees: feesFor(rate * statuses.length),
      seekerApprovedAt: t.subtract(const Duration(days: 5)),
      assistantApprovedAt: t.subtract(const Duration(days: 5)),
    );
    final b = createBooking(ag);
    agreements[ag.id] = ag.copyWith(bookingId: b.id);
    applications[app.id] = applications[app.id]!.copyWith(agreementId: ag.id);
    for (var i = 0; i < statuses.length; i++) {
      final pid = bookingPeriods[b.id]![i];
      periods[pid] = periods[pid]!.copyWith(
        status: statuses[i],
        paidAt: statuses[i] == PeriodStatus.settled
            ? t.subtract(const Duration(days: 20))
            : null,
      );
    }
    notifications[app.seeker.id]?.removeWhere((n) => n.targetId == b.id);
    notifications[app.assistant.id]?.removeWhere((n) => n.targetId == b.id);
    for (final pid in bookingPeriods[b.id]!) {
      if (periods[pid]!.status == PeriodStatus.settled) {
        final receives = feesFor(rate).assistantReceives;
        balances[app.assistant.id] =
            (balances[app.assistant.id] ?? 0) + receives;
        (walletTx[app.assistant.id] ??= []).add(
          WalletTx(
            id: _sid(),
            type: WalletTxType.earning,
            amount: receives,
            title: '${app.listingTitle} - periode 1',
            createdAt: t.subtract(const Duration(days: 18)),
          ),
        );
      }
    }
  }

  void _seed() {
    final rina = _user(
      'Bu Rina',
      '081234567890',
      {Role.seeker},
      rating: 4.8,
      ratingCount: 12,
    );
    final siti = _user(
      'Siti',
      '081298765432',
      {Role.assistant},
      rating: 4.9,
      ratingCount: 23,
      jobs: 23,
    );
    _user(
      'Bu Maya',
      '081355500002',
      {Role.seeker, Role.assistant},
      rating: 4.5,
      ratingCount: 4,
    );
    _user('Dewi', '081355500003', {Role.assistant}, verified: false);
    _user('Akun Ditangguhkan', '08999999999', {Role.seeker}, suspended: true);
    final yuni = _user(
      'Yuni',
      '081311110001',
      {Role.assistant},
      bot: true,
      rating: 4.7,
      ratingCount: 9,
      jobs: 9,
    );
    final ani = _user(
      'Ani',
      '081311110002',
      {Role.assistant},
      bot: true,
      rating: 4.6,
      ratingCount: 15,
      jobs: 15,
    );
    final lestari = _user(
      'Lestari',
      '081311110003',
      {Role.assistant},
      bot: true,
      rating: 4.8,
      ratingCount: 31,
      jobs: 31,
    );
    final hartini = _user(
      'Bu Hartini',
      '081311110011',
      {Role.seeker},
      bot: true,
      rating: 4.9,
      ratingCount: 7,
    );
    final agus = _user(
      'Pak Agus',
      '081311110012',
      {Role.seeker},
      bot: true,
      rating: 4.4,
      ratingCount: 3,
    );
    siti.skck = const Verification(status: VerificationStatus.verified);

    _profile(
      siti,
      ['Asisten Rumah Tangga', 'Juru Masak'],
      6,
      ['Memasak', 'Menyetrika', 'Kebersihan rumah'],
      1500000,
      PeriodUnit.monthly,
      'Jakarta Selatan',
      'Berpengalaman 6 tahun, rapi dan jujur.',
    );
    _profile(
      yuni,
      ['Pengasuh Anak'],
      4,
      ['Bayi 0-3 tahun', 'Membuat MPASI'],
      1900000,
      PeriodUnit.monthly,
      'Jakarta Selatan',
      'Sabar dan telaten dengan anak kecil.',
    );
    _profile(
      ani,
      ['Pengasuh Anak', 'Asisten Rumah Tangga'],
      8,
      ['Anak sekolah', 'Antar jemput'],
      650000,
      PeriodUnit.weekly,
      'Jakarta Timur',
      'Pernah bekerja di 3 keluarga, ada referensi.',
    );
    _profile(
      lestari,
      ['Perawat Lansia'],
      10,
      ['Perawatan stroke', 'Fisioterapi dasar'],
      3200000,
      PeriodUnit.monthly,
      'Bandung',
      'Perawat lansia bersertifikat.',
    );

    final l1 = _listing(
      rina,
      'Pengasuh anak usia 3 tahun',
      'Pengasuh Anak',
      'Jakarta Selatan',
      ListingStatus.open,
      1800000,
      2500000,
      PeriodUnit.monthly,
      6,
      applicants: 2,
    );
    _listing(
      rina,
      'Asisten rumah tangga harian',
      'Asisten Rumah Tangga',
      'Jakarta Selatan',
      ListingStatus.draft,
      80000,
      120000,
      PeriodUnit.daily,
      30,
    );
    final l3 = _listing(
      rina,
      'ART pulang-pergi',
      'Asisten Rumah Tangga',
      'Jakarta Selatan',
      ListingStatus.filled,
      1400000,
      1600000,
      PeriodUnit.monthly,
      3,
      applicants: 1,
    );
    _listing(
      rina,
      'Juru masak keluarga',
      'Juru Masak',
      'Jakarta Selatan',
      ListingStatus.awaitingPayment,
      1500000,
      2000000,
      PeriodUnit.monthly,
      3,
    );
    _listing(
      hartini,
      'Perawat lansia malam hari',
      'Perawat Lansia',
      'Bandung',
      ListingStatus.open,
      3000000,
      4000000,
      PeriodUnit.monthly,
      6,
      skck: true,
    );
    final l6 = _listing(
      agus,
      'Juru masak untuk 4 orang',
      'Juru Masak',
      'Jakarta Timur',
      ListingStatus.open,
      1700000,
      2200000,
      PeriodUnit.monthly,
      3,
      applicants: 1,
    );
    _listing(
      hartini,
      'ART mingguan',
      'Asisten Rumah Tangga',
      'Bandung',
      ListingStatus.open,
      500000,
      700000,
      PeriodUnit.weekly,
      8,
      skip: true,
    );
    final l8 = _listing(
      rina,
      'Pengasuh bayi',
      'Pengasuh Anak',
      'Jakarta Selatan',
      ListingStatus.filled,
      600000,
      700000,
      PeriodUnit.weekly,
      4,
      applicants: 1,
    );

    _application(
      l1,
      yuni,
      ApplicationStatus.shortlisted,
      1900000,
      'Saya pernah mengasuh anak usia 2-4 tahun selama 4 tahun.',
    );
    _application(
      l1,
      ani,
      ApplicationStatus.pending,
      2000000,
      'Siap bekerja mulai bulan depan.',
    );
    final a3 = _application(
      l3,
      siti,
      ApplicationStatus.accepted,
      1500000,
      'Saya biasa merapikan rumah dan memasak.',
    );
    final a4 = _application(
      l6,
      siti,
      ApplicationStatus.shortlisted,
      1800000,
      'Saya bisa memasak masakan rumahan dan diet.',
    );
    final a5 = _application(
      l8,
      ani,
      ApplicationStatus.accepted,
      600000,
      'Berpengalaman dengan bayi.',
    );

    _booking(a3, 1500000, PeriodUnit.monthly, [
      PeriodStatus.settled,
      PeriodStatus.awaitingPayment,
      PeriodStatus.awaitingPayment,
    ], const Duration(days: -20));
    _booking(a5, 600000, PeriodUnit.weekly, [
      PeriodStatus.settled,
      PeriodStatus.awaitingPayment,
      PeriodStatus.awaitingPayment,
      PeriodStatus.awaitingPayment,
    ], const Duration(days: -10));

    final slot = DateTime.utc(
      now().year,
      now().month,
      now().day,
      3,
    ).add(const Duration(days: 2));
    final i1 = Interview(
      id: _sid(),
      applicationId: a4.id,
      slots: [slot, slot.add(const Duration(days: 1))],
      status: InterviewStatus.proposed,
    );
    interviews[i1.id] = i1;
    applications[a4.id] = a4.copyWith(interviewId: i1.id);

    banks[siti.id] = ('BCA', '1234567890', 'Siti Nurhaliza');
    reviews.addAll([
      MockReview(
        Review(
          id: _sid(),
          bookingId: _sid(),
          reviewerName: 'Bu Hartini',
          stars: 5,
          comment: 'Siti rapi dan sangat bisa diandalkan.',
          createdAt: now().subtract(const Duration(days: 40)),
        ),
        hartini.id,
        siti.id,
      ),
      MockReview(
        Review(
          id: _sid(),
          bookingId: _sid(),
          reviewerName: 'Pak Agus',
          stars: 4,
          comment: 'Masakannya enak.',
          createdAt: now().subtract(const Duration(days: 80)),
          isAuto: false,
        ),
        agus.id,
        siti.id,
      ),
      MockReview(
        Review(
          id: _sid(),
          bookingId: _sid(),
          reviewerName: 'Bu Rina',
          stars: 5,
          createdAt: now().subtract(const Duration(days: 30)),
          isAuto: true,
        ),
        rina.id,
        yuni.id,
      ),
      MockReview(
        Review(
          id: _sid(),
          bookingId: _sid(),
          reviewerName: 'Siti',
          stars: 5,
          comment: 'Pencari ramah dan membayar tepat waktu.',
          createdAt: now().subtract(const Duration(days: 60)),
        ),
        siti.id,
        rina.id,
      ),
    ]);
    notify(
      rina.id,
      NotificationType.application,
      'Ada pelamar baru',
      'Ani melamar "Pengasuh anak usia 3 tahun".',
      applications.values
          .firstWhere((a) => a.assistant.id == ani.id && a.listingId == l1.id)
          .id,
    );
    notify(
      siti.id,
      NotificationType.interview,
      'Jadwal wawancara diajukan',
      'Pak Agus mengajukan jadwal wawancara. Pilih yang cocok.',
      i1.id,
    );
    notify(
      siti.id,
      NotificationType.booking,
      'Tagihan periode 2',
      'Pencari membayar sebelum periode dimulai. Kami kabari saat dana masuk.',
      applications[a3.id]!.bookingId,
    );
  }
}
