import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-04 Pilih peran (satu atau keduanya). Peran pertama yang dipilih jadi peran aktif.
class RoleScreen extends ConsumerStatefulWidget {
  const RoleScreen({super.key});

  @override
  ConsumerState<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends ConsumerState<RoleScreen> with ApiActionMixin {
  final _picked = <Role>[];

  void _toggle(Role r) => setState(() {
    _picked.contains(r) ? _picked.remove(r) : _picked.add(r);
  });

  Future<void> _continue() async {
    final session = ref.read(sessionProvider.notifier);
    final ok = await act(() async {
      await session.setRoles(_picked.toSet());
      if (ref.read(sessionProvider).activeRole != _picked.first) {
        await session.switchRole(_picked.first);
      }
    });
    // router tidak memindahkan layar ini sendiri (bukan rute publik)
    if (ok && mounted) {
      context.go(Routes.home(ref.read(sessionProvider).activeRole!));
    }
  }

  Widget _card(
    BuildContext context, {
    required Key key,
    required Role role,
    required IconData icon,
    required String title,
    required String body,
  }) {
    final t = context.tokens;
    final on = _picked.contains(role);
    final app = role == Role.seeker ? AppRole.seeker : AppRole.assistant;
    return Semantics(
      key: key,
      button: true,
      checked: on,
      excludeSemantics: true,
      label: '$title. $body',
      onTap: () => _toggle(role),
      child: InkWell(
        onTap: () => _toggle(role),
        borderRadius: AppRadius.brMd,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(AppSpace.s16),
          decoration: BoxDecoration(
            color: on ? t.roleContainer(app) : t.surface,
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: on ? t.roleColor(app) : t.borderSubtle,
              width: on ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: t.roleColor(app)),
              const SizedBox(width: AppSpace.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.h3),
                    Text(body, style: context.text.body),
                  ],
                ),
              ),
              if (on) Icon(LucideIcons.circleCheck, color: t.roleColor(app)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final both =
        _picked.contains(Role.seeker) && _picked.contains(Role.assistant);
    return AppScaffold(
      title: 'Pilih peran',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anda ingin memakai Pramu sebagai apa? Peran bisa diganti kapan saja.',
            style: context.text.body,
          ),
          const SizedBox(height: AppSpace.s16),
          if (actionError != null) ActionErrorBox(error: actionError!),
          _card(
            context,
            key: K.roleSeeker,
            role: Role.seeker,
            icon: LucideIcons.search,
            title: 'Cari asisten',
            body: 'Saya mencari asisten rumah tangga',
          ),
          const SizedBox(height: AppSpace.s12),
          _card(
            context,
            key: K.roleAssistant,
            role: Role.assistant,
            icon: LucideIcons.briefcase,
            title: 'Saya asisten',
            body: 'Saya mencari pekerjaan',
          ),
          const SizedBox(height: AppSpace.s8),
          CheckboxListTile(
            key: K.roleBoth,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: both,
            title: Text('Keduanya', style: context.text.body),
            onChanged: (v) => setState(() {
              _picked
                ..clear()
                ..addAll(v == true ? [Role.seeker, Role.assistant] : []);
            }),
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            key: K.roleContinue,
            label: 'Lanjut',
            large: true,
            loading: busy,
            onPressed: _picked.isEmpty || !canAct ? null : _continue,
          ),
        ],
      ),
    );
  }
}
