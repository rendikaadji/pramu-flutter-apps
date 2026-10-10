import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/platform/sensitive_files.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/theme_mode_controller.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/home/presentation/state/home_state.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/notification/data/push_providers.dart';
import 'package:pramu_apps/features/profile/data/my_profile_provider.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/shell_app_bar.dart';

/// M-24 Akun & pengaturan (+ M-22 ganti peran lewat sheet).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Widget _caption(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.s4,
      AppSpace.s24,
      AppSpace.s4,
      AppSpace.s8,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: context.text.label.copyWith(color: context.tokens.textMuted),
      ),
    ),
  );

  List<StatItem>? _stats(WidgetRef ref, bool isAssistant) {
    if (isAssistant) {
      final p = ref.watch(myProfileProvider).value;
      if (p == null) return null;
      return [
        StatItem('${p.completedJobs}', 'Selesai'),
        StatItem(
          p.ratingCount == 0 ? '-' : p.ratingAvg.toStringAsFixed(1),
          'Rating',
        ),
        StatItem('${p.ratingCount}', 'Ulasan'),
      ];
    }
    final h = ref.watch(seekerHomeProvider).value;
    if (h == null) return null;
    final active = h.bookings.where(
      (b) =>
          b.status == BookingStatus.active || b.status == BookingStatus.paused,
    );
    return [
      StatItem(
        '${h.listings.where((l) => l.status == ListingStatus.open).length}',
        'Lowongan',
      ),
      StatItem('${active.length}', 'Kontrak'),
      StatItem(
        '${h.bookings.where((b) => b.status == BookingStatus.completed).length}',
        'Selesai',
      ),
    ];
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda perlu masuk lagi untuk memakai Pramu.',
      confirmLabel: 'Keluar',
      destructive: true,
    );
    if (!ok) return;
    try {
      await sweepSensitiveFiles();
      await ref.read(pushTokenSyncProvider.notifier).unregister();
    } on Object {
      // best effort: logout tetap jalan (MOB-SEC-20)
    } finally {
      await ref.read(sessionProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider.select((s) => s.user));
    if (user == null) return const AppScaffold(body: SizedBox());
    final t = context.tokens;
    final mode = ref.watch(themeModeProvider);
    final isAssistant = user.activeRole == Role.assistant;
    final verified = user.verification;
    final seal = switch (verified) {
      VerificationStatus.verified => SealState.verified,
      VerificationStatus.pending => SealState.pending,
      VerificationStatus.rejected => SealState.rejected,
      _ => null,
    };
    final stats = _stats(ref, isAssistant);
    return AppScaffold(
      title: 'Akun',
      glow: true,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Row(
              children: [
                AvatarImage(name: user.name, size: 64),
                const SizedBox(width: AppSpace.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: context.text.h2),
                      Text(
                        maskPhone(user.phone),
                        style: context.text.bodySm.copyWith(color: t.textMuted),
                      ),
                      const SizedBox(height: AppSpace.s8),
                      if (seal != null)
                        VerificationSeal(state: seal, size: SealSize.sm)
                      else
                        Text(
                          verified.label,
                          style: context.text.bodySm.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (stats != null) ...[
            const SizedBox(height: AppSpace.s12),
            StatsRow(items: stats),
          ],
          _caption(context, isAssistant ? 'Identitas dan profil' : 'Identitas'),
          ListTileCard(
            children: [
              SettingsRow(
                icon: LucideIcons.shieldCheck,
                title: 'Verifikasi identitas',
                subtitle: verified.label,
                onTap: () => context.push(
                  verified == VerificationStatus.none
                      ? Routes.verificationGate
                      : Routes.verificationStatus,
                ),
              ),
              if (isAssistant) ...[
                SettingsRow(
                  icon: LucideIcons.fileCheck,
                  title: 'SKCK',
                  onTap: () => context.push(Routes.skck),
                ),
                SettingsRow(
                  icon: LucideIcons.userPen,
                  title: 'Ubah profil saya',
                  onTap: () => context.push(Routes.profileEdit),
                ),
                SettingsRow(
                  icon: LucideIcons.landmark,
                  title: 'Rekening bank',
                  onTap: () => context.push(Routes.bank),
                ),
              ],
            ],
          ),
          _caption(context, 'Pengaturan'),
          ListTileCard(
            children: [
              SettingsRow(
                key: K.accountRoleRow,
                icon: LucideIcons.repeat,
                title: 'Peran aktif',
                subtitle: user.activeRole == null
                    ? null
                    : 'Anda sedang masuk sebagai ${user.activeRole!.label}. '
                          'Ketuk untuk mengganti.',
                onTap: () => showRoleSwitch(context, ref),
              ),
              SettingsRow(
                icon: LucideIcons.bell,
                title: 'Notifikasi',
                onTap: () => context.push(Routes.notifications),
              ),
              SettingsRow(
                icon: LucideIcons.smartphone,
                title: 'Perangkat masuk',
                onTap: () => context.push(Routes.devices),
              ),
              SettingsRow(
                icon: LucideIcons.lock,
                title: 'Pusat privasi',
                onTap: () => context.push(Routes.privacy),
              ),
            ],
          ),
          _caption(context, 'Tema'),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpace.tap),
                backgroundColor: t.surface,
                foregroundColor: t.textPrimary,
                selectedBackgroundColor: t.primaryContainer,
                selectedForegroundColor: t.primary,
                side: BorderSide(color: t.borderSubtle),
                textStyle: context.text.label,
              ),
              segments: [
                for (final (key, m, label, icon) in [
                  (
                    K.themeSystem,
                    ThemeMode.system,
                    'Sistem',
                    LucideIcons.monitor,
                  ),
                  (K.themeLight, ThemeMode.light, 'Terang', LucideIcons.sun),
                  (K.themeDark, ThemeMode.dark, 'Gelap', LucideIcons.moon),
                ])
                  ButtonSegment<ThemeMode>(
                    value: m,
                    icon: Icon(icon, size: 18),
                    label: Text(label, key: key),
                  ),
              ],
              selected: {mode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ),
          const SizedBox(height: AppSpace.s32),
          ListTileCard(
            children: [
              SettingsRow(
                key: K.logout,
                icon: LucideIcons.logOut,
                title: 'Keluar',
                destructive: true,
                onTap: () => _logout(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          Center(
            child: Text(
              'Pramu ${Env.appVersion}',
              style: context.text.caption.copyWith(color: t.textSubtle),
            ),
          ),
        ],
      ),
    );
  }
}
