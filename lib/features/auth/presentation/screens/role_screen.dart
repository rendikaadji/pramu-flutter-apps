import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/auth/presentation/widgets/auth_widgets.dart';
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
    required Widget illustration,
  }) {
    final t = context.tokens;
    final on = _picked.contains(role);
    final app = role == Role.seeker ? AppRole.seeker : AppRole.assistant;
    final color = t.roleColor(app);
    return Semantics(
      key: key,
      button: true,
      checked: on,
      excludeSemantics: true,
      label: '$title. $body',
      onTap: () => _toggle(role),
      child: AnimatedContainer(
        duration: context.motion(AppMotion.fast),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: AppRadius.brCard,
          border: Border.all(
            color: on ? color : t.borderSubtle,
            width: on ? 2 : 1,
          ),
          boxShadow: t.e1,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card - 1),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => _toggle(role),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: t.roleContainer(app),
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
                    child: Center(child: illustration),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpace.s16),
                    child: Row(
                      children: [
                        Icon(icon, size: 28, color: color),
                        const SizedBox(width: AppSpace.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: context.text.h3),
                              Text(
                                body,
                                style: context.text.bodySm.copyWith(
                                  color: t.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.s8),
                        Icon(
                          on ? LucideIcons.circleCheck : LucideIcons.circle,
                          size: 28,
                          color: on ? color : t.borderStrong,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
      glow: true,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthHeader(
            icon: LucideIcons.users,
            title: 'Apa peran Anda di Pramu?',
            subtitle:
                'Pilih satu peran, atau keduanya. Anda bisa menggantinya '
                'kapan saja di menu Akun.',
          ),
          if (actionError != null) ActionErrorBox(error: actionError!),
          _card(
            context,
            key: K.roleSeeker,
            role: Role.seeker,
            icon: LucideIcons.search,
            title: 'Saya Pencari',
            body: 'Cari asisten untuk rumah Anda',
            illustration: const VerifyIllustration(size: 120),
          ),
          const SizedBox(height: AppSpace.s12),
          _card(
            context,
            key: K.roleAssistant,
            role: Role.assistant,
            icon: LucideIcons.briefcase,
            title: 'Saya Pelamar',
            body: 'Cari pekerjaan sebagai asisten',
            illustration: const MoneySafeIllustration(size: 120),
          ),
          const SizedBox(height: AppSpace.s8),
          CheckboxListTile(
            key: K.roleBoth,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: both,
            title: Text('Keduanya', style: context.text.label),
            subtitle: Text(
              'Saya mencari asisten dan juga mencari pekerjaan',
              style: context.text.bodySm.copyWith(
                color: context.tokens.textMuted,
              ),
            ),
            onChanged: (v) => setState(() {
              _picked
                ..clear()
                ..addAll(v == true ? [Role.seeker, Role.assistant] : []);
            }),
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            key: K.roleContinue,
            label: 'Lanjutkan',
            large: true,
            loading: busy,
            onPressed: _picked.isEmpty || !canAct ? null : _continue,
          ),
        ],
      ),
    );
  }
}
