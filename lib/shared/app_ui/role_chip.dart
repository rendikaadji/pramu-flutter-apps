import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';

IconData roleIcon(AppRole r) =>
    r == AppRole.seeker ? LucideIcons.search : LucideIcons.briefcase;

/// Chip peran permanen di app bar. Ketuk -> buka `showRoleSwitchSheet`.
class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.role, this.onTap});

  final AppRole role;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = t.roleColor(role);
    return Semantics(
      button: onTap != null,
      label: 'Peran aktif: ${role.label}. Ketuk untuk ganti peran',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpace.tap),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.roleContainer(role),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: fg.withValues(alpha: .4)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s12,
                  vertical: AppSpace.s8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon(role), size: 18, color: fg),
                    const SizedBox(width: AppSpace.s8),
                    Text(
                      role.label,
                      style: context.text.label.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: AppSpace.s4),
                      Icon(LucideIcons.chevronDown, size: 18, color: fg),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Isi sheet "Gunakan sebagai". UI saja: tidak mengubah state apa pun.
class RoleSwitchSheet extends StatelessWidget {
  const RoleSwitchSheet({
    super.key,
    required this.current,
    required this.onSelect,
    this.available = const {AppRole.seeker, AppRole.assistant},
    this.onAddRole,
  });

  final AppRole current;
  final Set<AppRole> available;
  final ValueChanged<AppRole> onSelect;

  /// Dipanggil dengan peran yang belum dimiliki ("Tambah peran Asisten").
  final ValueChanged<AppRole>? onAddRole;

  static String _desc(AppRole r) => r == AppRole.seeker
      ? 'Cari dan pekerjakan asisten'
      : 'Cari lowongan dan melamar kerja';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16,
          0,
          AppSpace.s16,
          AppSpace.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text('Gunakan sebagai', style: context.text.h2),
            ),
            const SizedBox(height: AppSpace.s12),
            for (final r in AppRole.values) ...[
              if (available.contains(r))
                Semantics(
                  button: true,
                  selected: r == current,
                  excludeSemantics: true,
                  label:
                      '${r.label}. ${_desc(r)}${r == current ? '. Sedang dipakai' : ''}',
                  onTap: () => onSelect(r),
                  child: InkWell(
                    onTap: () => onSelect(r),
                    borderRadius: AppRadius.brMd,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.all(AppSpace.s12),
                      decoration: BoxDecoration(
                        color: r == current ? t.roleContainer(r) : null,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(
                          color: r == current ? t.roleColor(r) : t.borderSubtle,
                          width: r == current ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(roleIcon(r), color: t.roleColor(r)),
                          const SizedBox(width: AppSpace.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.label, style: context.text.h3),
                                Text(_desc(r), style: context.text.bodySm),
                              ],
                            ),
                          ),
                          if (r == current)
                            Icon(LucideIcons.check, color: t.roleColor(r)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                AppButton(
                  label: 'Tambah peran ${r.label}',
                  icon: LucideIcons.plus,
                  variant: AppButtonVariant.secondary,
                  onPressed: onAddRole == null ? null : () => onAddRole!(r),
                ),
              const SizedBox(height: AppSpace.s8),
            ],
          ],
        ),
      ),
    );
  }
}

/// Buka sheet ganti peran; sheet ditutup sebelum callback dipanggil.
Future<void> showRoleSwitchSheet(
  BuildContext context, {
  required AppRole current,
  required ValueChanged<AppRole> onSelect,
  Set<AppRole> available = const {AppRole.seeker, AppRole.assistant},
  ValueChanged<AppRole>? onAddRole,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheet) => RoleSwitchSheet(
    current: current,
    available: available,
    onSelect: (r) {
      Navigator.pop(sheet);
      if (r != current) onSelect(r);
    },
    onAddRole: onAddRole == null
        ? null
        : (r) {
            Navigator.pop(sheet);
            onAddRole(r);
          },
  ),
);
