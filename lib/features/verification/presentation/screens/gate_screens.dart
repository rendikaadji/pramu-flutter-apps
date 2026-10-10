import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/pinned_actions_bar.dart';

/// M-10 Gerbang verifikasi. Akun yang sudah dikirim/terverifikasi dialihkan.
class VerificationGateScreen extends ConsumerWidget {
  const VerificationGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider.select((s) => s.user));
    final status = user?.verification ?? VerificationStatus.none;
    if (status != VerificationStatus.none) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final role = user?.activeRole;
        context.go(
          status.isVerified && role != null
              ? Routes.home(role)
              : Routes.verificationStatus,
        );
      });
      return const AppScaffold(body: SizedBox());
    }
    final t = context.tokens;
    Widget step(int n, IconData icon, String text) => Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: context.text.label.copyWith(color: t.primary),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.s12),
        Expanded(child: Text(text, style: context.text.body)),
        ExcludeSemantics(child: Icon(icon, color: t.textMuted)),
      ],
    );
    final divider = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
      child: Divider(height: 1, color: t.borderSubtle),
    );
    return AppScaffold(
      title: 'Verifikasi identitas',
      glow: true,
      scrollable: true,
      bottomNavigationBar: PinnedActionsBar(
        children: [
          AppButton(
            key: K.verificationStart,
            label: 'Mulai verifikasi',
            large: true,
            onPressed: () => context.push(Routes.verificationGuide),
          ),
          const SizedBox(height: AppSpace.s4),
          AppButton(
            key: K.verificationLater,
            label: 'Nanti dulu',
            variant: AppButtonVariant.text,
            onPressed: () async {
              final role = user?.activeRole;
              await ref
                  .read(sessionProvider.notifier)
                  .markVerificationGateSeen();
              if (context.mounted && role != null) {
                context.go(Routes.home(role));
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: VerifyIllustration(size: 200)),
          const SizedBox(height: AppSpace.s16),
          Semantics(
            header: true,
            child: Text('Verifikasi dalam 3 menit', style: context.text.h1),
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            'Agar semua pengguna aman, kami perlu memastikan Anda orang yang '
            'sebenarnya.',
            style: context.text.body.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: AppSpace.s24),
          AppCard(
            child: Column(
              children: [
                step(1, LucideIcons.idCard, 'Foto KTP'),
                divider,
                step(2, LucideIcons.scanFace, 'Selfie sambil memegang KTP'),
                divider,
                step(3, LucideIcons.send, 'Kirim dan tunggu hasil'),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          const PrivacyNote(
            'Foto KTP hanya dipakai untuk verifikasi, disimpan terenkripsi, '
            'dan hanya dibuka petugas yang berwenang.',
          ),
          const SizedBox(height: AppSpace.s16),
          Text(
            'Tanpa verifikasi Anda hanya bisa menjelajah, belum bisa memasang '
            'lowongan atau melamar.',
            style: context.text.bodySm.copyWith(color: t.textMuted),
          ),
        ],
      ),
    );
  }
}

/// M-11 Panduan foto.
class VerificationGuideScreen extends StatelessWidget {
  const VerificationGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget tip(
      IconData icon,
      Color color,
      Color container,
      String title,
      String body,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: container,
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.h3),
                  const SizedBox(height: AppSpace.s4),
                  Text(
                    body,
                    style: context.text.bodySm.copyWith(color: t.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return AppScaffold(
      title: 'Panduan foto',
      glow: true,
      scrollable: true,
      bottomNavigationBar: PinnedActionsBar(
        children: [
          AppButton(
            label: 'Siap',
            large: true,
            onPressed: () => context.push(Routes.verificationKtp),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpace.s8),
          Text(
            'Foto yang jelas membuat verifikasi lebih cepat.',
            style: context.text.h2,
          ),
          const SizedBox(height: AppSpace.s16),
          tip(
            LucideIcons.sun,
            t.success,
            t.successContainer,
            'Tempat terang',
            'Gunakan cahaya cukup, tanpa pantulan atau bayangan di KTP.',
          ),
          tip(
            LucideIcons.scanLine,
            t.success,
            t.successContainer,
            'Semua sudut terlihat',
            'Seluruh KTP masuk bingkai, tulisan terbaca jelas.',
          ),
          tip(
            LucideIcons.circleX,
            t.danger,
            t.dangerContainer,
            'Hindari',
            'Foto buram, terpotong, atau KTP tertutup jari dan kacamata.',
          ),
        ],
      ),
    );
  }
}
