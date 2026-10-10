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
import 'package:pramu_apps/features/notification/data/push_providers.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/shell_app_bar.dart';

/// M-24 Akun & pengaturan (+ M-22 ganti peran lewat sheet).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Widget _row(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    final t = context.tokens;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: value == null ? label : '$label, $value',
      onTap: onTap,
      child: InkWell(
        key: key,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpace.tap),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s16,
              vertical: AppSpace.s8,
            ),
            child: Row(
              children: [
                Icon(icon, color: t.textMuted),
                const SizedBox(width: AppSpace.s16),
                Expanded(child: Text(label, style: context.text.body)),
                if (value != null)
                  Text(
                    value,
                    style: context.text.bodySm.copyWith(color: t.textMuted),
                  ),
                const SizedBox(width: AppSpace.s8),
                Icon(LucideIcons.chevronRight, color: t.textSubtle, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  /// Satu kartu berisi baris-baris menu dengan pemisah di antaranya.
  Widget _group(BuildContext context, List<Widget> rows) {
    final t = context.tokens;
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpace.s16 + 24 + AppSpace.s16,
                    color: t.borderSubtle,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ),
    );
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
    return AppScaffold(
      title: 'Akun',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Row(
              children: [
                AvatarImage(name: user.name, size: 56),
                const SizedBox(width: AppSpace.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: context.text.h3),
                      Text(
                        maskPhone(user.phone),
                        style: context.text.bodySm.copyWith(color: t.textMuted),
                      ),
                      const SizedBox(height: AppSpace.s4),
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
          _caption(context, isAssistant ? 'Identitas & profil' : 'Identitas'),
          _group(context, [
            _row(
              context,
              icon: LucideIcons.shieldCheck,
              label: 'Verifikasi identitas',
              value: verified.label,
              onTap: () => context.push(
                verified == VerificationStatus.none
                    ? Routes.verificationGate
                    : Routes.verificationStatus,
              ),
            ),
            if (isAssistant) ...[
              _row(
                context,
                icon: LucideIcons.fileCheck,
                label: 'SKCK',
                onTap: () => context.push(Routes.skck),
              ),
              _row(
                context,
                icon: LucideIcons.userPen,
                label: 'Edit profil asisten',
                onTap: () => context.push(Routes.profileEdit),
              ),
              _row(
                context,
                icon: LucideIcons.landmark,
                label: 'Rekening bank',
                onTap: () => context.push(Routes.bank),
              ),
            ],
          ]),
          _caption(context, 'Pengaturan'),
          _group(context, [
            _row(
              context,
              key: K.accountRoleRow,
              icon: LucideIcons.repeat,
              label: 'Ganti peran',
              value: user.activeRole?.label,
              onTap: () => showRoleSwitch(context, ref),
            ),
            _row(
              context,
              icon: LucideIcons.bell,
              label: 'Notifikasi',
              onTap: () => context.push(Routes.notifications),
            ),
            _row(
              context,
              icon: LucideIcons.smartphone,
              label: 'Perangkat masuk',
              onTap: () => context.push(Routes.devices),
            ),
            _row(
              context,
              icon: LucideIcons.lock,
              label: 'Pusat privasi',
              onTap: () => context.push(Routes.privacy),
            ),
          ]),
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
          AppButton(
            key: K.logout,
            label: 'Keluar',
            icon: LucideIcons.logOut,
            variant: AppButtonVariant.secondary,
            onPressed: () => _logout(context, ref),
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
