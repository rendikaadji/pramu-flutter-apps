import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/shell_app_bar.dart';

/// Kepala beranda di atas glow: avatar (ke Akun), sapaan, chip peran (M-22), lonceng (M-23).
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider.select((s) => s.user));
    final role = user?.activeRole;
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s16,
        AppSpace.s8,
        AppSpace.s8,
        AppSpace.s4,
      ),
      child: Row(
        children: [
          if (user != null)
            Semantics(
              button: true,
              label: 'Akun dan pengaturan',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => context.go(
                  user.activeRole == Role.assistant
                      ? Routes.assistantAccount
                      : Routes.seekerAccount,
                ),
                customBorder: const CircleBorder(),
                child: SizedBox.square(
                  dimension: AppSpace.tap,
                  child: Center(
                    child: AvatarImage(
                      name: user.name,
                      url: user.photoUrl,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${user?.name ?? ''}',
                  style: context.text.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: context.text.caption.copyWith(color: t.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (role != null)
            RoleChip(
              key: K.roleSwitchChip,
              role: appRoleOf(role),
              onTap: () => showRoleSwitch(context, ref),
            ),
          AppIconButton(
            key: K.notificationBell,
            icon: LucideIcons.bell,
            label: 'Notifikasi',
            onPressed: () => context.push(Routes.notifications),
          ),
        ],
      ),
    );
  }
}

/// Baris kategori populer. Semua ubin membuka layar cari (`route`).
class HomeCategoryRow extends StatelessWidget {
  const HomeCategoryRow({super.key, required this.route});

  final String route;

  static const _items = [
    (LucideIcons.house, 'Asisten rumah'),
    (LucideIcons.baby, 'Pengasuh anak'),
    (LucideIcons.heartPulse, 'Perawat lansia'),
    (LucideIcons.chefHat, 'Juru masak'),
  ];

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (icon, label) in _items)
        Expanded(
          child: CategoryTile(
            icon: icon,
            label: label,
            onTap: () => context.go(route),
          ),
        ),
    ],
  );
}
