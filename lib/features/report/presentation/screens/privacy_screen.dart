import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/report/presentation/screens/report_status_screen.dart';
import 'package:pramu_apps/features/report/presentation/state/report_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

const _visibility = <(String, String)>[
  ('Profil', 'Terlihat oleh pengguna yang membuka lowongan atau profil Anda.'),
  ('Nomor HP dan email', 'Tersembunyi sampai pembayaran dilakukan.'),
  (
    'Percakapan',
    'Hanya Anda dan lawan bicara, kecuali Anda sendiri yang membagikannya.',
  ),
  ('KTP dan selfie', 'Hanya petugas verifikasi yang berwenang.'),
  ('Catatan wawancara', 'Hanya Anda.'),
];

const _visibilityIcons = [
  LucideIcons.user,
  LucideIcons.phone,
  LucideIcons.messageCircle,
  LucideIcons.idCard,
  LucideIcons.fileText,
];

/// M-25 Pusat privasi: siapa melihat apa + riwayat laporan & persetujuan berbagi chat.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final reports = ref.watch(reportListProvider);
    final now = DateTime.now().toUtc();
    return AppScaffold(
      title: 'Pusat privasi',
      glow: true,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Siapa yang bisa melihat apa'),
          ListTileCard(
            children: [
              for (final (i, (what, who)) in _visibility.indexed)
                MergeSemantics(
                  child: SettingsRow(
                    icon: _visibilityIcons[i % _visibilityIcons.length],
                    title: what,
                    subtitle: who,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s24),
          const SectionHeader('Laporan dan persetujuan Anda'),
          reports.when(
            loading: () => const ListSkeleton(
              count: 2,
              kind: SkeletonCardKind.notification,
            ),
            error: (e, _) => ApiErrorView(
              error: asApiException(e),
              onRetry: () => ref.invalidate(reportListProvider),
            ),
            data: (list) => list.isEmpty
                ? const EmptyState(
                    compact: true,
                    title: 'Belum ada riwayat',
                    message:
                        'Laporan dan persetujuan Anda akan muncul di sini.',
                  )
                : Column(
                    children: [
                      for (final r in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.s12),
                          child: AppCard(
                            onTap: () =>
                                context.push(Routes.reportStatus(r.id)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.type.label,
                                        style: context.text.label,
                                      ),
                                      Text(
                                        r.share == null
                                            ? 'Percakapan tidak dibagikan'
                                            : shareLabel(r.share!, now),
                                        style: context.text.bodySm.copyWith(
                                          color: t.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusChip(
                                  label: r.status.label,
                                  tone: StatusTone.info,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: 'Laporkan masalah',
            icon: LucideIcons.flag,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push(Routes.reportNew),
          ),
        ],
      ),
    );
  }
}
