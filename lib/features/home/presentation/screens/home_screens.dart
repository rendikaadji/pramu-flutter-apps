import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/home/presentation/state/home_state.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/shell_app_bar.dart';
import 'package:pramu_apps/shared/app_ui/status_presets.dart';

/// Banner verifikasi (belum verified): tombol ke gerbang atau status.
class _VerifyBanner extends ConsumerWidget {
  const _VerifyBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      sessionProvider.select((s) => s.user?.verification),
    );
    if (status == null || status.isVerified) return const SizedBox.shrink();
    final t = context.tokens;
    final (text, action) = switch (status) {
      VerificationStatus.pending => (
        'Verifikasi Anda sedang diperiksa. Fitur penuh aktif setelah selesai.',
        'Lihat status',
      ),
      VerificationStatus.rejected => (
        'Verifikasi belum berhasil. Unggah ulang berkas Anda.',
        'Perbaiki sekarang',
      ),
      _ => (
        'Verifikasi dulu untuk memasang lowongan atau melamar.',
        'Verifikasi sekarang',
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s16),
      child: AppCard(
        key: K.homeVerifyBanner,
        color: t.warningContainer,
        borderColor: t.warning.withValues(alpha: .4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldAlert, color: t.warning),
                const SizedBox(width: AppSpace.s12),
                Expanded(child: Text(text, style: context.text.body)),
              ],
            ),
            const SizedBox(height: AppSpace.s12),
            AppButton(
              label: action,
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: () => context.push(
                status == VerificationStatus.none
                    ? Routes.verificationGate
                    : Routes.verificationStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile(this.b, this.role);
  final Booking b;
  final Role role;

  @override
  Widget build(BuildContext context) {
    final app = role == Role.seeker ? AppRole.seeker : AppRole.assistant;
    final other = role == Role.seeker ? b.assistant.name : b.seeker.name;
    final current = b.periods.where((p) => !p.status.isFinal).firstOrNull;
    final summary = current == null
        ? b.status.label
        : 'Periode ${current.index} dari ${b.periods.length}, '
              '${current.status.labelFor(role).toLowerCase()}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: AppCard(
        onTap: () => context.push(Routes.bookingDetail(b.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.listingTitle, style: context.text.h3),
            Text(other, style: context.text.bodySm),
            const SizedBox(height: AppSpace.s12),
            LedgerMini(
              summary: summary,
              tones: [
                for (final p in b.periods)
                  statusPreset(StatusDomain.period, wire(p.status), app).tone,
              ],
            ),
            const SizedBox(height: AppSpace.s8),
            Text(summary, style: context.text.bodySm),
          ],
        ),
      ),
    );
  }
}

Widget _loadingSkeleton() => const Padding(
  padding: EdgeInsets.symmetric(vertical: AppSpace.s16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppSkeleton.box(96, radius: AppRadius.md),
      SizedBox(height: AppSpace.s16),
      AppSkeleton.line(width: 160),
      SizedBox(height: AppSpace.s12),
      AppSkeleton.box(72, radius: AppRadius.md),
    ],
  ),
);

/// M-20 Beranda Pencari.
class SeekerHomeScreen extends ConsumerWidget {
  const SeekerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(seekerHomeProvider);
    return Scaffold(
      appBar: const ShellAppBar(title: 'Beranda'),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpace.maxContent),
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(seekerHomeProvider.future),
              child: AsyncBody<SeekerHome>(
                value: value,
                onRetry: () => ref.invalidate(seekerHomeProvider),
                skeleton: Semantics(label: 'Memuat', child: _loadingSkeleton()),
                data: (context, d) => _seeker(context, d),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _seeker(BuildContext context, SeekerHome d) {
    final next = d.next;
    final listings = d.listings
        .where(
          (l) =>
              l.status == ListingStatus.open ||
              l.status == ListingStatus.draft ||
              l.status == ListingStatus.awaitingPayment,
        )
        .take(3)
        .toList();
    final bookings = d.bookings
        .where(
          (b) =>
              b.status == BookingStatus.active ||
              b.status == BookingStatus.paused,
        )
        .toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpace.s16),
      children: [
        const _VerifyBanner(),
        if (next != null) ...[
          NextStepCard(
            key: K.homeNextStep,
            title: next.title,
            message: next.message,
            onTap: () => context.push(next.route),
          ),
          const SizedBox(height: AppSpace.s16),
        ],
        if (d.isNewUser)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s16),
            child: Column(
              children: [
                const EmptyState(
                  icon: LucideIcons.clipboardList,
                  title: 'Mulai dari sini',
                  message: 'Pasang lowongan atau cari asisten yang sudah terverifikasi.',
                ),
                AppButton(
                  key: K.homeCreateListing,
                  label: 'Buat lowongan pertama',
                  large: true,
                  onPressed: () => context.push(Routes.listingNew),
                ),
                const SizedBox(height: AppSpace.s12),
                AppButton(
                  key: K.homeFindAssistant,
                  label: 'Cari asisten',
                  variant: AppButtonVariant.secondary,
                  large: true,
                  onPressed: () => context.go(Routes.seekerSearch),
                ),
              ],
            ),
          )
        else ...[
          SectionHeader(
            'Lowongan aktif',
            actionLabel: 'Lihat semua',
            onAction: () => context.go(Routes.seekerJobs),
          ),
          if (listings.isEmpty)
            Text('Belum ada lowongan aktif.', style: context.text.body),
          for (final l in listings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s12),
              child: AppCard(
                onTap: () => context.push(switch (l.status) {
                  ListingStatus.draft => '${Routes.listingNew}?draft=${l.id}',
                  ListingStatus.awaitingPayment => Routes.listingPay(l.id),
                  _ => Routes.listingManage(l.id),
                }),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.title, style: context.text.h3),
                    const SizedBox(height: AppSpace.s8),
                    Wrap(
                      spacing: AppSpace.s8,
                      runSpacing: AppSpace.s4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip.of(StatusDomain.listing, wire(l.status)),
                        Text(
                          '${l.applicantCount} pelamar',
                          style: context.text.bodySm,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          AppButton(
            key: K.homeCreateListing,
            label: 'Buat lowongan',
            icon: LucideIcons.plus,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push(Routes.listingNew),
          ),
          SectionHeader(
            'Kontrak berjalan',
            actionLabel: 'Lihat semua',
            onAction: () => context.push(Routes.contracts),
          ),
          if (bookings.isEmpty)
            Text(
              'Belum ada kontrak. Kontrak dibuat setelah Anda dan asisten sepakat.',
              style: context.text.body,
            ),
          for (final b in bookings) _BookingTile(b, Role.seeker),
        ],
      ],
    );
  }
}

/// M-21 Beranda Asisten.
class AssistantHomeScreen extends ConsumerWidget {
  const AssistantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(assistantHomeProvider);
    return Scaffold(
      appBar: const ShellAppBar(title: 'Beranda'),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpace.maxContent),
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(assistantHomeProvider.future),
              child: AsyncBody<AssistantHome>(
                value: value,
                onRetry: () => ref.invalidate(assistantHomeProvider),
                skeleton: Semantics(label: 'Memuat', child: _loadingSkeleton()),
                data: (context, d) => _assistant(context, d),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _assistant(BuildContext context, AssistantHome d) {
    final t = context.tokens;
    final next = d.next;
    final meter = d.profile?.completeness ?? 0;
    final bookings = d.bookings
        .where(
          (b) =>
              b.status == BookingStatus.active ||
              b.status == BookingStatus.paused,
        )
        .toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpace.s16),
      children: [
        const _VerifyBanner(),
        if (next != null) ...[
          NextStepCard(
            key: K.homeNextStep,
            role: AppRole.assistant,
            title: next.title,
            message: next.message,
            onTap: () => context.push(next.route),
          ),
          const SizedBox(height: AppSpace.s16),
        ],
        if (meter < 100)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s16),
            child: AppCard(
              key: K.homeProfileMeter,
              onTap: () => context.push(Routes.profileEdit),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.profile == null
                        ? 'Buat profil Anda'
                        : 'Profil Anda $meter% lengkap',
                    style: context.text.h3,
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Semantics(
                    label: 'Kelengkapan profil $meter persen',
                    excludeSemantics: true,
                    child: LinearProgressIndicator(
                      value: meter / 100,
                      minHeight: 8,
                      borderRadius: AppRadius.brXs,
                      color: t.accent,
                      backgroundColor: t.borderSubtle,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    'Profil lengkap lebih mudah dipilih pencari.',
                    style: context.text.bodySm,
                  ),
                ],
              ),
            ),
          ),
        if (d.isNewUser && d.profile != null)
          EmptyState(
            icon: LucideIcons.search,
            title: 'Belum ada aktivitas',
            message:
                'Cari lowongan yang cocok lalu kirim lamaran pertama Anda.',
            actionLabel: 'Cari lowongan',
            onAction: () => context.go(Routes.assistantListings),
          )
        else ...[
          if (d.suggested.isNotEmpty) ...[
            SectionHeader(
              'Lowongan untuk Anda',
              actionLabel: 'Lihat semua',
              onAction: () => context.go(Routes.assistantListings),
            ),
            for (final l in d.suggested)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s12),
                child: AppCard(
                  onTap: () => context.push(Routes.listingDetail(l.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.title, style: context.text.h3),
                      Text(
                        '${l.category} - ${l.city}',
                        style: context.text.bodySm,
                      ),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        '${formatRupiah(l.budgetMin)} - '
                        '${formatRupiah(l.budgetMax)} per ${l.unit.label.toLowerCase()}',
                        style: context.text.body,
                      ),
                    ],
                  ),
                ),
              ),
          ],
          SectionHeader(
            'Kontrak berjalan',
            actionLabel: 'Lihat semua',
            onAction: () => context.push(Routes.contracts),
          ),
          if (bookings.isEmpty)
            Text('Belum ada kontrak berjalan.', style: context.text.body),
          for (final b in bookings) _BookingTile(b, Role.assistant),
        ],
      ],
    );
  }
}
