import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

AppRole appRoleOf(Role r) =>
    r == Role.seeker ? AppRole.seeker : AppRole.assistant;

/// M-22: sheet "Gunakan Pramu sebagai". Dipakai app bar shell dan layar Akun.
Future<void> showRoleSwitch(BuildContext context, WidgetRef ref) async {
  final user = ref.read(sessionProvider).user;
  final active = user?.activeRole;
  if (user == null || active == null) return;
  final messenger = ScaffoldMessenger.of(context);
  final session = ref.read(sessionProvider.notifier);

  Future<void> run(Role target, {bool add = false}) async {
    try {
      if (add) await session.setRoles({...user.roles, target});
      await session.switchRole(target);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Sekarang sebagai ${target.label}')),
        );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  await showRoleSwitchSheet(
    context,
    current: appRoleOf(active),
    available: {for (final r in user.roles) appRoleOf(r)},
    onSelect: (r) => run(Role.values.byName(r.name)),
    onAddRole: (r) => run(Role.values.byName(r.name), add: true),
  );
}

/// App bar tab root: judul, chip peran (M-22), lonceng (M-23), avatar -> Akun (M-24).
class ShellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ShellAppBar({super.key, required this.title});
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider.select((s) => s.user));
    final role = user?.activeRole;
    return AppBar(
      title: Text(title),
      actions: [
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
        if (user != null)
          Semantics(
            button: true,
            label: 'Akun dan pengaturan',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => user.activeRole == Role.assistant
                  ? context.go(Routes.assistantAccount)
                  : context.push(Routes.account),
              customBorder: const CircleBorder(),
              child: SizedBox.square(
                dimension: AppSpace.tap,
                child: Center(child: AvatarImage(name: user.name, size: 32)),
              ),
            ),
          ),
        const SizedBox(width: AppSpace.s4),
      ],
    );
  }
}
