import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/application/data/application_providers.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/interview/data/interview_providers.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/listing/data/listing_providers.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/profile/data/profile_providers.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';

void _user(Ref ref) => ref.watch(sessionProvider.select((s) => s.user?.id));

final applicationProvider = FutureProvider.autoDispose
    .family<Application, String>((ref, id) {
      _user(ref);
      return ref.watch(applicationRepositoryProvider).get(id);
    }, retry: noRetry);

final myApplicationsProvider = FutureProvider.autoDispose<List<Application>>((
  ref,
) {
  _user(ref);
  return ref.watch(applicationRepositoryProvider).mine();
}, retry: noRetry);

final myInvitationsProvider = FutureProvider.autoDispose<List<Invitation>>((
  ref,
) {
  _user(ref);
  return ref.watch(applicationRepositoryProvider).invitations();
}, retry: noRetry);

/// Wawancara untuk satu lamaran (null bila belum ada).
final applicationInterviewProvider = FutureProvider.autoDispose
    .family<Interview?, String>((ref, applicationId) {
      _user(ref);
      return ref
          .watch(interviewRepositoryProvider)
          .byApplication(applicationId);
    }, retry: noRetry);

/// Lowongan terbuka milik pencari (untuk M-32).
final openOwnListingsProvider = FutureProvider.autoDispose<List<Listing>>((
  ref,
) async {
  _user(ref);
  final all = await ref.watch(listingRepositoryProvider).mine();
  return [
    for (final l in all)
      if (l.status == ListingStatus.open) l,
  ];
}, retry: noRetry);

final assistantProfileProvider = FutureProvider.autoDispose
    .family<AssistantProfile, String>((ref, userId) {
      return ref.watch(profileRepositoryProvider).assistant(userId);
    }, retry: noRetry);

/// Lowongan + tarif profil sendiri untuk form lamar (M-43).
class ApplyContext {
  const ApplyContext(this.listing, this.defaultRate);
  final Listing listing;
  final int? defaultRate;
}

final applyContextProvider = FutureProvider.autoDispose
    .family<ApplyContext, String>((ref, listingId) async {
      _user(ref);
      final listing = await ref.watch(listingRepositoryProvider).get(listingId);
      int? rate;
      try {
        final p = await ref.watch(profileRepositoryProvider).myProfile();
        if (p != null && p.rate > 0) rate = p.rate;
      } catch (_) {
        // tarif default hanya kemudahan; abaikan bila gagal
      }
      return ApplyContext(listing, rate);
    }, retry: noRetry);

/// Detail pelamar (M-37): lamaran + lowongan + profil asisten (untuk kartu kepercayaan).
class ApplicantDetail {
  const ApplicantDetail(this.application, this.listing, this.profile);
  final Application application;
  final Listing listing;
  final AssistantProfile? profile;
}

final applicantDetailProvider = FutureProvider.autoDispose
    .family<ApplicantDetail, String>((ref, id) async {
      _user(ref);
      final app = await ref.watch(applicationRepositoryProvider).get(id);
      final listing = await ref
          .watch(listingRepositoryProvider)
          .get(app.listingId);
      AssistantProfile? profile;
      try {
        profile = await ref
            .watch(profileRepositoryProvider)
            .assistant(app.assistant.id);
      } catch (_) {
        // kartu kepercayaan jatuh ke data ringkas pada lamaran
      }
      return ApplicantDetail(app, listing, profile);
    }, retry: noRetry);
