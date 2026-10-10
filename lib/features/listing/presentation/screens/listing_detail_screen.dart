import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/presentation/state/listing_state.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/listing_card.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-42 Detail lowongan (asisten). Pencari pemilik dialihkan ke M-36.
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingDetailProvider(id));
    final user = ref.watch(sessionProvider.select((s) => s.user));
    final l = async.value;
    if (l != null && user != null && l.owner.id == user.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pushReplacement(Routes.listingManage(id));
      });
    }
    return AppScaffold(
      title: 'Detail lowongan',
      body: AsyncBody<Listing>(
        value: async,
        onRetry: () => ref.invalidate(listingDetailProvider(id)),
        data: (ctx, l) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(listingDetailProvider(id)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: AppSpace.s8,
              bottom: AppSpace.s24,
            ),
            children: [
              _Body(listing: l),
              const SizedBox(height: AppSpace.s24),
              if (user?.activeRole == Role.assistant) _Cta(listing: l),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final t = context.tokens;
    final days = daysLeft(l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.title, style: context.text.h1),
        const SizedBox(height: AppSpace.s8),
        Wrap(
          spacing: AppSpace.s8,
          runSpacing: AppSpace.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusChip.of(StatusDomain.listing, wire(l.status)),
            if (l.requireSkck)
              const StatusChip(
                label: 'Wajib SKCK',
                tone: StatusTone.neutral,
                icon: LucideIcons.fileCheck,
              ),
            if (days != null) Text('Sisa $days hari'),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l.category} - ${l.city}', style: context.text.body),
              const SizedBox(height: AppSpace.s4),
              Text(budgetText(l), style: context.text.body),
              Text(
                '${l.periodCount} periode, mulai ${formatDate(l.startDate)}',
                style: context.text.body,
              ),
            ],
          ),
        ),
        if (l.description.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s16),
          Text(l.description, style: context.text.body),
        ],
        const SizedBox(height: AppSpace.s16),
        const SectionHeader('Pemberi kerja'),
        const SizedBox(height: AppSpace.s8),
        AppCard(
          child: Row(
            children: [
              AvatarImage(name: l.owner.name, url: l.owner.photoUrl, size: 48),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.owner.name, style: context.text.h3),
                    if (l.owner.verified)
                      const VerificationSeal(size: SealSize.sm),
                    if (l.owner.ratingCount > 0)
                      RatingStars(
                        value: l.owner.ratingAvg,
                        count: l.owner.ratingCount,
                      )
                    else
                      Text(
                        'Belum ada ulasan',
                        style: context.text.bodySm.copyWith(color: t.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Cta extends ConsumerWidget {
  const _Cta({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = listing;
    final mine = ref.watch(myApplicationForListingProvider(l.id));
    final skck = l.requireSkck
        ? ref.watch(mySkckStatusProvider)
        : const AsyncData(VerificationStatus.verified);

    if (mine.isLoading || skck.isLoading) {
      return Semantics(
        label: 'Memuat',
        child: const AppSkeleton(height: AppSpace.tap),
      );
    }
    final existing = mine.value;
    if (existing != null || l.applied) {
      return AppButton(
        key: K.listingViewApplication,
        label: 'Lihat lamaran',
        variant: AppButtonVariant.secondary,
        onPressed: existing == null
            ? null
            : () => context.push(Routes.applicationDetail(existing.id)),
      );
    }
    if (!l.status.acceptsApplications) {
      return _Locked(
        message: l.status == ListingStatus.filled
            ? 'Lowongan ini sudah terisi.'
            : 'Lowongan ini sudah ditutup atau berakhir.',
      );
    }
    final status = skck.value ?? VerificationStatus.none;
    if (l.requireSkck && !status.isVerified) {
      final pending = status == VerificationStatus.pending;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pending
                ? 'SKCK Anda sedang ditinjau. Anda bisa melamar setelah terverifikasi.'
                : 'Lowongan ini mewajibkan SKCK. Unggah SKCK Anda sekali, bisa dipakai untuk lamaran lain.',
            style: context.text.body,
          ),
          const SizedBox(height: AppSpace.s12),
          AppButton(
            key: K.listingUploadSkck,
            label: pending ? 'Lihat status SKCK' : 'Unggah SKCK untuk melamar',
            icon: LucideIcons.lock,
            onPressed: () => context.push('${Routes.skck}?listing=${l.id}'),
          ),
        ],
      );
    }
    return AppButton(
      key: K.listingApply,
      label: 'Lamar sekarang',
      large: true,
      onPressed: () => context.push(Routes.apply(l.id)).then((_) {
        ref.invalidate(myApplicationForListingProvider(l.id));
        ref.invalidate(listingDetailProvider(l.id));
        final browse = ref.read(listingBrowseProvider.notifier);
        browse.reload(filter: browse.filter, keep: true);
      }),
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AppButton(label: 'Lamar sekarang', onPressed: null),
      const SizedBox(height: AppSpace.s8),
      Text(message, style: context.text.bodySm),
    ],
  );
}
