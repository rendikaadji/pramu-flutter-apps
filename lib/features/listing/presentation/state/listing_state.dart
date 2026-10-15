import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/application/data/application_providers.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/listing/data/listing_providers.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/presentation/state/paged_notifier.dart';
import 'package:pramu_apps/features/profile/data/profile_providers.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';
import 'package:pramu_apps/features/verification/data/verification_providers.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';

/// M-30: pencarian asisten (pencari).
class AssistantSearchNotifier
    extends PagedNotifier<AssistantProfile, AssistantFilter> {
  @override
  AssistantFilter get emptyFilter => const AssistantFilter();

  @override
  Future<Paged<AssistantProfile>> fetch(AssistantFilter f, String? cursor) =>
      ref.read(profileRepositoryProvider).search(f, cursor: cursor);
}

final assistantSearchProvider =
    NotifierProvider.autoDispose<
      AssistantSearchNotifier,
      PagedState<AssistantProfile>
    >(AssistantSearchNotifier.new);

/// M-41: lowongan terbuka (asisten).
class ListingBrowseNotifier extends PagedNotifier<Listing, ListingFilter> {
  @override
  ListingFilter get emptyFilter => const ListingFilter();

  @override
  Future<Paged<Listing>> fetch(ListingFilter f, String? cursor) =>
      ref.read(listingRepositoryProvider).browse(f, cursor: cursor);
}

final listingBrowseProvider =
    NotifierProvider.autoDispose<ListingBrowseNotifier, PagedState<Listing>>(
      ListingBrowseNotifier.new,
    );

/// M-35.
final myListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  return ref.watch(listingRepositoryProvider).mine();
}, retry: noRetry);

/// M-36 / M-42 / M-34 / M-43 (satu lowongan).
final listingDetailProvider = FutureProvider.autoDispose
    .family<Listing, String>((ref, id) {
      ref.watch(sessionProvider.select((s) => s.user?.id));
      return ref.watch(listingRepositoryProvider).get(id);
    }, retry: noRetry);

/// M-36: pelamar suatu lowongan.
final listingApplicantsProvider = FutureProvider.autoDispose
    .family<List<Application>, String>((ref, id) {
      ref.watch(sessionProvider.select((s) => s.user?.id));
      return ref.watch(applicationRepositoryProvider).forListing(id);
    }, retry: noRetry);

/// M-42: lamaran aktif saya pada lowongan ini (null bila belum melamar).
final myApplicationForListingProvider = FutureProvider.autoDispose
    .family<Application?, String>((ref, listingId) async {
      ref.watch(sessionProvider.select((s) => s.user?.id));
      final all = await ref.watch(applicationRepositoryProvider).mine();
      return all
          .where((a) => a.listingId == listingId && a.status.isActive)
          .firstOrNull;
    }, retry: noRetry);

/// M-42: status SKCK saya.
final mySkckStatusProvider = FutureProvider.autoDispose<VerificationStatus>((
  ref,
) async {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  return (await ref.watch(verificationRepositoryProvider).skck()).status;
}, retry: noRetry);
