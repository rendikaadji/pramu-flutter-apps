import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
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
import 'package:pramu_apps/shared/app_ui/compact_rating.dart';
import 'package:pramu_apps/shared/app_ui/icon_info_row.dart';
import 'package:pramu_apps/shared/app_ui/pinned_actions_bar.dart';

/// M-42 Detail lowongan (asisten). Pencari pemilik dialihkan ke M-36.
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingDetailProvider(id));
    final user = ref.watch(sessionProvider.select((s) => s.user));
    final l = async.value;
    final assistant = user?.activeRole == Role.assistant;
    if (l != null && user != null && l.owner.id == user.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pushReplacement(Routes.listingManage(id));
      });
    }
    return AppScaffold(
      title: 'Detail lowongan',
      glow: true,
      bottomNavigationBar: l == null
          ? null
          : assistant
          ? PinnedActionsBar(children: [_Cta(listing: l)])
          : PinnedActionsBar(
              children: [
                Text(
                  'Ini lowongan milik pencari lain. Beralih ke peran Pelamar untuk melamar.',
                  style: context.text.bodySm.copyWith(
                    color: context.tokens.textMuted,
                  ),
                ),
              ],
            ),
      body: AsyncBody<Listing>(
        value: async,
        onRetry: () => ref.invalidate(listingDetailProvider(id)),
        skeleton: const DetailSkeleton(),
        data: (ctx, l) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(listingDetailProvider(id)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: AppSpace.s8,
              bottom: AppSpace.s24,
            ),
            children: [_Body(listing: l, assistantView: assistant)],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.listing, required this.assistantView});
  final Listing listing;
  final bool assistantView;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final t = context.tokens;
    final days = daysLeft(l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero info: ikon kategori, judul, kota, budget mono.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.primaryContainer,
                  borderRadius: AppRadius.brCard,
                ),
                child: SizedBox.square(
                  dimension: 56,
                  child: Icon(
                    categoryIcon(l.category),
                    color: t.primary,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.title, style: context.text.h1),
                  const SizedBox(height: AppSpace.s4),
                  IconInfoRow(icon: LucideIcons.mapPin, text: l.city),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s12),
        Wrap(
          spacing: AppSpace.s8,
          runSpacing: AppSpace.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusChip.of(StatusDomain.listing, wire(l.status)),
            if (days != null)
              Text(
                'Sisa $days hari',
                style: context.text.bodySm.copyWith(color: t.textMuted),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        AppCard(
          color: t.primaryContainer,
          borderColor: t.primary.withValues(alpha: .18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget per ${l.unit.label.toLowerCase()}',
                style: context.text.caption.copyWith(color: t.textMuted),
              ),
              const SizedBox(height: AppSpace.s4),
              MoneyText(
                '${formatRupiah(l.budgetMin)} - ${formatRupiah(l.budgetMax)}',
              ),
            ],
          ),
        ),
        if (l.requireSkck) ...[
          const SizedBox(height: AppSpace.s12),
          _SkckPanel(assistantView: widget.assistantView),
        ],
        const SizedBox(height: AppSpace.s20),
        SegmentedTabs(
          labels: const ['Deskripsi', 'Persyaratan', 'Pencari'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: AppSpace.s16),
        switch (_tab) {
          0 => _Description(listing: l),
          1 => _Requirements(listing: l),
          _ => _Owner(listing: l),
        },
      ],
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Tentang pekerjaan'),
        Text(
          l.description.isEmpty
              ? 'Pencari belum menulis deskripsi.'
              : l.description,
          style: context.text.body,
        ),
      ],
    );
  }
}

class _Requirements extends StatelessWidget {
  const _Requirements({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    return ListTileCard(
      children: [
        SettingsRow(
          icon: LucideIcons.briefcase,
          title: 'Kategori',
          subtitle: l.category,
        ),
        SettingsRow(icon: LucideIcons.mapPin, title: 'Kota', subtitle: l.city),
        SettingsRow(
          icon: LucideIcons.calendar,
          title: 'Durasi',
          subtitle:
              '${l.periodCount} periode, mulai ${formatDate(l.startDate)}',
        ),
        SettingsRow(
          icon: LucideIcons.fileCheck,
          title: 'SKCK',
          subtitle: l.requireSkck ? 'Wajib terverifikasi' : 'Tidak diwajibkan',
        ),
      ],
    );
  }
}

class _Owner extends StatelessWidget {
  const _Owner({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final t = context.tokens;
    return AppCard(
      child: Row(
        children: [
          AvatarImage(name: l.owner.name, url: l.owner.photoUrl, size: 56),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.owner.name, style: context.text.h3),
                const SizedBox(height: AppSpace.s4),
                if (l.owner.verified) const VerificationSeal(size: SealSize.sm),
                if (l.owner.ratingCount > 0)
                  CompactRating(
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
    );
  }
}

/// Panel syarat SKCK: tinta nada sukses bila sudah terverifikasi, peringatan bila belum.
class _SkckPanel extends ConsumerWidget {
  const _SkckPanel({required this.assistantView});
  final bool assistantView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    var ok = false;
    var message = 'Hanya pelamar dengan SKCK terverifikasi yang bisa melamar.';
    if (assistantView) {
      final status =
          ref.watch(mySkckStatusProvider).value ?? VerificationStatus.none;
      ok = status.isVerified;
      message = ok
          ? 'SKCK Anda sudah terverifikasi. Anda bisa melamar.'
          : status == VerificationStatus.pending
          ? 'SKCK Anda sedang diperiksa. Anda bisa melamar setelah verifikasi selesai.'
          : 'Lowongan ini mewajibkan SKCK. Unggah SKCK Anda sekali, bisa dipakai untuk lamaran lain.';
    }
    final tone = ok ? StatusTone.success : StatusTone.warning;
    return AppCard(
      color: tone.bg(t),
      borderColor: tone.fg(t).withValues(alpha: .35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(LucideIcons.fileCheck, size: 22, color: tone.fg(t)),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wajib SKCK', style: context.text.label),
                const SizedBox(height: AppSpace.s4),
                Text(message, style: context.text.bodySm),
              ],
            ),
          ),
        ],
      ),
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
      return const InlineSkeleton(
        height: AppSpace.tap,
        radius: AppRadius.button,
      );
    }
    final existing = mine.value;
    if (existing != null || l.applied) {
      return AppButton(
        key: K.listingViewApplication,
        label: 'Lihat lamaran',
        icon: LucideIcons.fileText,
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
            : 'Lowongan ini sudah ditutup.',
      );
    }
    final status = skck.value ?? VerificationStatus.none;
    if (l.requireSkck && !status.isVerified) {
      final pending = status == VerificationStatus.pending;
      return AppButton(
        key: K.listingUploadSkck,
        label: pending ? 'Lihat status SKCK' : 'Unggah SKCK untuk melamar',
        icon: LucideIcons.lock,
        onPressed: () => context.push('${Routes.skck}?listing=${l.id}'),
      );
    }
    return AppButton(
      key: K.listingApply,
      label: 'Lamar sekarang',
      icon: LucideIcons.send,
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
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AppButton(label: 'Lamar sekarang', onPressed: null),
      const SizedBox(height: AppSpace.s8),
      Text(message, style: context.text.bodySm),
    ],
  );
}
