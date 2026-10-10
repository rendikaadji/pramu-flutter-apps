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
import 'package:pramu_apps/features/home/presentation/widgets/home_header.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
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
    final seeker = ref.watch(
      sessionProvider.select((s) => s.activeRole == Role.seeker),
    );
    final (title, text, action) = switch (status) {
      VerificationStatus.pending => (
        'Verifikasi sedang diperiksa',
        'Biasanya selesai dalam 1x24 jam. Kami kabari lewat notifikasi.',
        'Lihat status',
      ),
      VerificationStatus.rejected => (
        'Verifikasi belum berhasil',
        'Kirim ulang dengan foto yang lebih jelas.',
        'Kirim ulang',
      ),
      _ => (
        'Verifikasi identitas Anda',
        seeker
            ? 'Verifikasi dulu sebelum memasang lowongan.'
            : 'Verifikasi dulu sebelum melamar pekerjaan.',
        'Mulai verifikasi',
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s16),
      child: HeroBannerCard(
        key: K.homeVerifyBanner,
        title: title,
        subtitle: text,
        ctaLabel: action,
        illustration: const VerifyIllustration(size: 104),
        onTap: () => context.push(
          status == VerificationStatus.none
              ? Routes.verificationGate
              : Routes.verificationStatus,
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

/// Baris lowongan Pencari: status + sisa waktu, judul, lalu satu baris tindakan
/// yang menyesuaikan status (jumlah pelamar / lanjutkan draf / bayar).
String _listingRoute(Listing l) => switch (l.status) {
  ListingStatus.draft => '${Routes.listingNew}?draft=${l.id}',
  ListingStatus.awaitingPayment => Routes.listingPay(l.id),
  _ => Routes.listingManage(l.id),
};

/// Banner "Langkah berikutnya" (hero lembut) dengan caption.
class _NextHero extends StatelessWidget {
  const _NextHero({required this.next, this.illustration});
  final NextStep next;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.s16),
    child: HeroBannerCard(
      key: K.homeNextStep,
      title: next.title,
      subtitle: next.message,
      ctaLabel: 'Lanjutkan',
      illustration: illustration ?? const MoneySafeIllustration(size: 104),
      onTap: () => context.push(next.route),
    ),
  );
}

class _ListingTile extends StatelessWidget {
  const _ListingTile(this.l);
  final Listing l;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final exp = l.expiresAt;
    String? remain;
    if (l.status == ListingStatus.open && exp != null) {
      final d = exp.difference(DateTime.now()).inDays;
      remain = d <= 0 ? 'Berakhir hari ini' : 'Sisa $d hari';
    }
    final (IconData icon, String text, Color color) = switch (l.status) {
      ListingStatus.draft => (LucideIcons.pencil, 'Lanjutkan draf', t.primary),
      ListingStatus.awaitingPayment => (
        LucideIcons.creditCard,
        'Selesaikan pembayaran',
        t.textPrimary,
      ),
      _ when l.applicantCount > 0 => (
        LucideIcons.users,
        '${l.applicantCount} pelamar',
        t.primary,
      ),
      _ => (LucideIcons.users, 'Belum ada pelamar', t.textMuted),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: AppCard(
        onTap: () => context.push(_listingRoute(l)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: StatusChip.of(StatusDomain.listing, wire(l.status)),
                ),
                if (remain != null) ...[
                  const Spacer(),
                  Text(
                    remain,
                    style: context.text.caption.copyWith(color: t.textMuted),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.s12),
            Text(l.title, style: context.text.h3),
            const SizedBox(height: AppSpace.s4),
            Text(
              '${l.category} - ${l.city}',
              style: context.text.bodySm.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: AppSpace.s12),
            Row(
              children: [
                ExcludeSemantics(child: Icon(icon, size: 18, color: color)),
                const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: Text(
                    text,
                    style: context.text.label.copyWith(color: color),
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 20, color: t.textSubtle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// M-20 Beranda Pencari.
class SeekerHomeScreen extends ConsumerWidget {
  const SeekerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(seekerHomeProvider);
    return AppScaffold(
      glow: true,
      padded: false,
      body: Column(
        children: [
          const HomeHeader(subtitle: 'Temukan asisten tepercaya'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(seekerHomeProvider.future),
              child: AsyncBody<SeekerHome>(
                value: value,
                onRetry: () => ref.invalidate(seekerHomeProvider),
                skeleton: const HomeSkeleton(),
                data: (context, d) => _seeker(context, d),
              ),
            ),
          ),
        ],
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
        SearchField(
          hint: 'Cari asisten',
          onTap: () => context.go(Routes.seekerSearch),
        ),
        const SizedBox(height: AppSpace.s16),
        const HomeCategoryRow(route: Routes.seekerSearch),
        const SizedBox(height: AppSpace.s20),
        const _VerifyBanner(),
        if (next != null) _NextHero(next: next),
        if (d.isNewUser)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s16),
            child: Column(
              children: [
                const EmptyState(
                  icon: LucideIcons.clipboardList,
                  title: 'Mulai dari sini',
                  message:
                      'Pasang lowongan, atau cari langsung asisten yang '
                      'sudah terverifikasi.',
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
            Text(
              'Belum ada lowongan aktif. Buat lowongan agar asisten bisa '
              'melamar.',
              style: context.text.body,
            ),
          for (final (i, l) in listings.indexed)
            if (i == 0 &&
                l.status == ListingStatus.open &&
                l.applicantCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s12),
                child: FeaturedCard(
                  title: l.title,
                  subtitle: '${l.category} - ${l.city}',
                  tags: ['${l.applicantCount} pelamar'],
                  leadingIcon: LucideIcons.users,
                  onTap: () => context.push(_listingRoute(l)),
                ),
              )
            else
              _ListingTile(l),
          AppButton(
            key: K.homeCreateListing,
            label: 'Buat lowongan',
            icon: LucideIcons.plus,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push(Routes.listingNew),
          ),
          const SizedBox(height: AppSpace.s16),
          SectionHeader(
            'Kontrak berjalan',
            actionLabel: 'Lihat semua',
            onAction: () => context.push(Routes.contracts),
          ),
          if (bookings.isEmpty)
            Text(
              'Belum ada kontrak. Kontrak muncul setelah Anda dan asisten sepakat.',
              style: context.text.body,
            ),
          for (final b in bookings) _BookingTile(b, Role.seeker),
        ],
      ],
    );
  }
}

/// M-21 Beranda Pelamar.
class AssistantHomeScreen extends ConsumerWidget {
  const AssistantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(assistantHomeProvider);
    return AppScaffold(
      glow: true,
      padded: false,
      body: Column(
        children: [
          const HomeHeader(subtitle: 'Temukan pekerjaan yang cocok'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(assistantHomeProvider.future),
              child: AsyncBody<AssistantHome>(
                value: value,
                onRetry: () => ref.invalidate(assistantHomeProvider),
                skeleton: const HomeSkeleton(),
                data: (context, d) => _assistant(context, d),
              ),
            ),
          ),
        ],
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
        SearchField(
          hint: 'Cari lowongan',
          onTap: () => context.go(Routes.assistantListings),
        ),
        const SizedBox(height: AppSpace.s16),
        const HomeCategoryRow(route: Routes.assistantListings),
        const SizedBox(height: AppSpace.s20),
        const _VerifyBanner(),
        if (next != null)
          _NextHero(
            next: next,
            illustration: const WelcomeIllustration(size: 104),
          ),
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
                    'Profil yang lengkap lebih mudah dipilih Pencari.',
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
            for (final (i, l) in d.suggested.indexed)
              if (i == 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s12),
                  child: FeaturedCard(
                    title: l.title,
                    subtitle: '${l.category} - ${l.city}',
                    tags: [l.category],
                    trailing:
                        '${formatRupiah(l.budgetMin)} / '
                        '${l.unit.label.toLowerCase()}',
                    onTap: () => context.push(Routes.listingDetail(l.id)),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s12),
                  child: AppCard(
                    onTap: () => context.push(Routes.listingDetail(l.id)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.title, style: context.text.h3),
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          '${l.category} - ${l.city}',
                          style: context.text.bodySm.copyWith(
                            color: context.tokens.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpace.s12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: MoneyText(
                                '${formatRupiah(l.budgetMin)} - '
                                '${formatRupiah(l.budgetMax)}',
                                size: MoneySize.small,
                              ),
                            ),
                            const SizedBox(width: AppSpace.s4),
                            Text(
                              'per ${l.unit.label.toLowerCase()}',
                              style: context.text.bodySm.copyWith(
                                color: context.tokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: AppSpace.s16),
          SectionHeader(
            'Kontrak berjalan',
            actionLabel: 'Lihat semua',
            onAction: () => context.push(Routes.contracts),
          ),
          if (bookings.isEmpty)
            Text(
              'Belum ada kontrak berjalan. Kontrak muncul setelah lamaran '
              'Anda diterima.',
              style: context.text.body,
            ),
          for (final b in bookings) _BookingTile(b, Role.assistant),
        ],
      ],
    );
  }
}
