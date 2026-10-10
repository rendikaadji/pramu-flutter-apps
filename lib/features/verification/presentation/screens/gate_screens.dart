import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

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
    Widget step(int n, IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
      child: Row(
        children: [
          ExcludeSemantics(child: Icon(icon, color: t.primary)),
          const SizedBox(width: AppSpace.s12),
          Expanded(child: Text('$n. $text', style: context.text.body)),
        ],
      ),
    );
    return AppScaffold(
      title: 'Verifikasi identitas',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: VerificationSeal(
              state: SealState.pending,
              size: SealSize.lg,
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Text(
            'Agar semua pengguna aman, kami perlu memastikan Anda orang yang '
            'sebenarnya. Cukup 3 menit.',
            style: context.text.h3,
          ),
          const SizedBox(height: AppSpace.s16),
          step(1, LucideIcons.idCard, 'Foto KTP'),
          step(2, LucideIcons.scanFace, 'Selfie sambil memegang KTP'),
          step(3, LucideIcons.send, 'Kirim dan tunggu hasil'),
          const SizedBox(height: AppSpace.s16),
          const PrivacyNote(
            'Foto KTP hanya dipakai untuk verifikasi, disimpan terenkripsi, '
            'dan hanya dibuka petugas yang berwenang.',
          ),
          const SizedBox(height: AppSpace.s24),
          AppButton(
            key: K.verificationStart,
            label: 'Mulai verifikasi',
            large: true,
            onPressed: () => context.push(Routes.verificationGuide),
          ),
          const SizedBox(height: AppSpace.s12),
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
    Widget tip(IconData icon, Color color, String title, String body) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s12),
          child: AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(icon, color: color)),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.h3),
                      Text(body, style: context.text.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return AppScaffold(
      title: 'Panduan foto',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto yang jelas membuat verifikasi lebih cepat.',
            style: context.text.body,
          ),
          const SizedBox(height: AppSpace.s16),
          tip(
            LucideIcons.sun,
            t.success,
            'Tempat terang',
            'Gunakan cahaya cukup, tanpa pantulan atau bayangan di KTP.',
          ),
          tip(
            LucideIcons.scanLine,
            t.success,
            'Semua sudut terlihat',
            'Seluruh KTP masuk bingkai, tulisan terbaca jelas.',
          ),
          tip(
            LucideIcons.circleX,
            t.danger,
            'Hindari',
            'Foto buram, terpotong, atau KTP tertutup jari dan kacamata.',
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: 'Siap',
            large: true,
            onPressed: () => context.push(Routes.verificationKtp),
          ),
        ],
      ),
    );
  }
}
