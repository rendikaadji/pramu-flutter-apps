import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/profile/data/profile_providers.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

final assistantProfileProvider = FutureProvider.autoDispose
    .family<AssistantProfile, String>((ref, id) {
      ref.watch(sessionProvider.select((s) => s.user?.id));
      return ref.watch(profileRepositoryProvider).assistant(id);
    }, retry: (_, _) => null);

void _explainSeal(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  builder: (_) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apa arti terverifikasi?', style: context.text.h2),
          const SizedBox(height: AppSpace.s8),
          Text(
            'KTP dan selfie pengguna ini sudah ditinjau petugas Pramu. '
            'Ini bukan jaminan perilaku, jadi tetap periksa ulasan dan '
            'lakukan wawancara.',
            style: context.text.body,
          ),
        ],
      ),
    ),
  ),
);

/// M-31 Profil publik asisten. Tanpa HP/alamat; kontak tersamar sampai pembayaran.
class AssistantProfileScreen extends ConsumerWidget {
  const AssistantProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(assistantProfileProvider(userId));
    final me = ref.watch(sessionProvider.select((s) => s.user));
    return AppScaffold(
      title: 'Profil asisten',
      padded: false,
      body: AsyncBody<AssistantProfile>(
        value: value,
        onRetry: () => ref.invalidate(assistantProfileProvider(userId)),
        skeleton: Padding(
          padding: const EdgeInsets.all(AppSpace.s16),
          child: Semantics(
            label: 'Memuat',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton.box(72, radius: 36),
                SizedBox(height: AppSpace.s16),
                AppSkeleton.line(width: 200),
                SizedBox(height: AppSpace.s12),
                AppSkeleton.box(120, radius: AppRadius.md),
              ],
            ),
          ),
        ),
        data: (context, p) => _body(context, p, me),
      ),
    );
  }

  Widget _body(BuildContext context, AssistantProfile p, AuthUser? me) {
    final t = context.tokens;
    final own = me?.id == p.userId;
    return ListView(
      padding: const EdgeInsets.all(AppSpace.s16),
      children: [
        Row(
          children: [
            AvatarImage(name: p.name, url: p.photoUrl, size: 72),
            const SizedBox(width: AppSpace.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(p.name, style: context.text.h1),
                  ),
                  if (p.verified)
                    VerificationSeal(
                      size: SealSize.sm,
                      onTap: () => _explainSeal(context),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        TrustCard(
          seal: p.verified ? SealState.verified : SealState.pending,
          rating: p.ratingCount > 0 ? p.ratingAvg : null,
          reviewCount: p.ratingCount,
          completedJobs: p.completedJobs,
          onSealTap: p.verified ? () => _explainSeal(context) : null,
        ),
        const SizedBox(height: AppSpace.s16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: [
                  for (final c in p.categories)
                    StatusChip(label: c, tone: StatusTone.info),
                  StatusChip(
                    label: p.available ? 'Tersedia' : 'Belum tersedia',
                    tone: p.available ? StatusTone.success : StatusTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s12),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 18, color: t.textMuted),
                  const SizedBox(width: AppSpace.s8),
                  Expanded(child: Text(p.city, style: context.text.body)),
                ],
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                '${p.experienceYears} tahun pengalaman',
                style: context.text.body,
              ),
              const SizedBox(height: AppSpace.s8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  MoneyText(formatRupiah(p.rate)),
                  Text(
                    ' per ${p.unit.label.toLowerCase()}',
                    style: context.text.body,
                  ),
                ],
              ),
              if (p.skills.isNotEmpty) ...[
                const SizedBox(height: AppSpace.s12),
                Text('Keahlian', style: context.text.h3),
                const SizedBox(height: AppSpace.s8),
                Wrap(
                  spacing: AppSpace.s8,
                  runSpacing: AppSpace.s8,
                  children: [
                    for (final s in p.skills)
                      StatusChip(label: s, tone: StatusTone.neutral),
                  ],
                ),
              ],
              if (p.bio.isNotEmpty) ...[
                const SizedBox(height: AppSpace.s12),
                Text(p.bio, style: context.text.body),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        const PrivacyNote(
          'Nomor HP disembunyikan sampai pembayaran dilakukan, demi keamanan Anda.',
        ),
        const SizedBox(height: AppSpace.s16),
        AppButton(
          label: 'Lihat ulasan',
          icon: LucideIcons.star,
          variant: AppButtonVariant.secondary,
          onPressed: () => context.push(Routes.userReviews(p.userId)),
        ),
        const SizedBox(height: AppSpace.s12),
        if (own)
          AppButton(
            key: K.profileEdit,
            label: 'Edit profil',
            icon: LucideIcons.pencil,
            onPressed: () => context.push(Routes.profileEdit),
          )
        else if (me?.activeRole == Role.seeker)
          AppButton(
            key: K.profileInvite,
            label: 'Ajak melamar',
            icon: LucideIcons.userPlus,
            large: true,
            onPressed: () => context.push(Routes.invite(p.userId)),
          ),
      ],
    );
  }
}
