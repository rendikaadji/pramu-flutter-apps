import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/application/data/application_providers.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/booking/data/booking_providers.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/interview/data/interview_providers.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/listing/data/listing_providers.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/profile/data/my_profile_provider.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';

/// Satu tugas terpenting sekarang; `route` dari `Routes` (tanpa PII).
class NextStep {
  const NextStep(this.title, this.message, this.route);
  final String title;
  final String message;
  final String route;
}

Iterable<BookingPeriod> _periods(List<Booking> bs) => bs
    .where(
      (b) =>
          b.status == BookingStatus.active || b.status == BookingStatus.paused,
    )
    .expand((b) => b.periods);

/// Pencari: tagihan -> konfirmasi selesai -> pelamar -> lowongan belum tayang.
NextStep? seekerNextStep(List<Listing> listings, List<Booking> bookings) {
  final due = _periods(bookings).where((p) => p.status.canPay).toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  if (due.isNotEmpty) {
    final p = due.first;
    return NextStep(
      'Tagihan periode ${p.index} jatuh tempo ${formatDate(p.dueAt)}',
      'Bayar agar kontrak tetap berjalan.',
      Routes.periodPay(p.id),
    );
  }
  for (final p in _periods(bookings)) {
    if (p.status.canConfirmComplete) {
      return NextStep(
        'Konfirmasi pekerjaan periode ${p.index} selesai',
        'Dana dicairkan ke asisten setelah Anda konfirmasi.',
        Routes.periodConfirm(p.id),
      );
    }
  }
  for (final l in listings) {
    if (l.status == ListingStatus.open && l.applicantCount > 0) {
      return NextStep(
        '${l.applicantCount} pelamar menunggu',
        l.title,
        Routes.listingManage(l.id),
      );
    }
  }
  for (final l in listings) {
    if (l.status == ListingStatus.awaitingPayment) {
      return NextStep(
        'Bayar biaya pasang lowongan',
        l.title,
        Routes.listingPay(l.id),
      );
    }
    if (l.status == ListingStatus.draft) {
      return NextStep(
        'Lanjutkan draf lowongan',
        l.title,
        '${Routes.listingNew}?draft=${l.id}',
      );
    }
  }
  return null;
}

/// Asisten: wawancara -> lamaran diterima -> menunggu konfirmasi pencari.
NextStep? assistantNextStep(
  List<Application> apps,
  Interview? interview,
  List<Booking> bookings,
) {
  if (interview != null) {
    if (interview.status == InterviewStatus.proposed) {
      return NextStep(
        'Konfirmasi jadwal wawancara',
        'Pilih satu dari ${interview.slots.length} waktu yang diajukan.',
        Routes.interviewConfirm(interview.id),
      );
    }
    final slot = interview.confirmedSlot;
    if (interview.status == InterviewStatus.confirmed && slot != null) {
      return NextStep(
        'Wawancara ${formatDateTime(slot)}',
        'Buka detail untuk melihat cara bergabung.',
        Routes.interviewDetail(interview.id),
      );
    }
  }
  for (final a in apps) {
    if (a.status == ApplicationStatus.accepted && a.bookingId == null) {
      return NextStep(
        'Lamaran Anda diterima ${a.seeker.name}',
        'Lanjutkan ke kesepakatan kerja.',
        Routes.applicationDetail(a.id),
      );
    }
  }
  for (final b in bookings) {
    for (final p in b.periods) {
      if (p.status.canConfirmComplete) {
        return NextStep(
          'Menunggu konfirmasi ${b.seeker.name}',
          'Periode ${p.index} sudah selesai. Dana dicairkan setelah '
              'dikonfirmasi.',
          Routes.bookingDetail(b.id),
        );
      }
    }
  }
  return null;
}

class SeekerHome {
  const SeekerHome(this.listings, this.bookings);
  final List<Listing> listings;
  final List<Booking> bookings;
  NextStep? get next => seekerNextStep(listings, bookings);
  bool get isNewUser => listings.isEmpty && bookings.isEmpty;
}

class AssistantHome {
  const AssistantHome({
    required this.applications,
    required this.bookings,
    required this.profile,
    required this.suggested,
    required this.interview,
  });
  final List<Application> applications;
  final List<Booking> bookings;
  final AssistantProfile? profile;
  final List<Listing> suggested;
  final Interview? interview;
  NextStep? get next => assistantNextStep(applications, interview, bookings);
  bool get isNewUser =>
      applications.isEmpty && bookings.isEmpty && suggested.isEmpty;
}

final seekerHomeProvider = FutureProvider.autoDispose<SeekerHome>((ref) async {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  final (listings, bookings) = await (
    ref.watch(listingRepositoryProvider).mine(),
    ref.watch(bookingRepositoryProvider).bookings(),
  ).wait;
  return SeekerHome(listings, bookings);
}, retry: (_, _) => null);

final assistantHomeProvider = FutureProvider.autoDispose<AssistantHome>((
  ref,
) async {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  final listings = ref.watch(listingRepositoryProvider);
  final (apps, bookings, profile) = await (
    ref.watch(applicationRepositoryProvider).mine(),
    ref.watch(bookingRepositoryProvider).bookings(),
    ref.watch(myProfileProvider.future),
  ).wait;

  // Rekomendasi: gagal (mis. 403 belum verified) tidak boleh menggagalkan beranda.
  var suggested = <Listing>[];
  try {
    suggested = (await listings.browse(
      ListingFilter(city: profile?.city.isEmpty ?? true ? null : profile!.city),
    )).items.where((l) => !l.applied).take(3).toList();
  } on ApiException {
    // tampil tanpa rekomendasi
  }

  // Wawancara aktif: yang menunggu konfirmasi didahulukan, lalu yang terjadwal.
  Interview? interview;
  final interviews = ref.watch(interviewRepositoryProvider);
  for (final a in apps.where(
    (a) => a.interviewId != null && a.status.isActive,
  )) {
    try {
      final i = await interviews.get(a.interviewId!);
      if (i.status == InterviewStatus.proposed) {
        interview = i;
        break;
      }
      if (i.status == InterviewStatus.confirmed) interview ??= i;
    } on ApiException {
      // lewati; langkah berikutnya jatuh ke aturan lain
    }
  }
  return AssistantHome(
    applications: apps,
    bookings: bookings,
    profile: profile,
    suggested: suggested,
    interview: interview,
  );
}, retry: (_, _) => null);
