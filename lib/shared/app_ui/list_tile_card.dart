import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

/// Kartu berisi baris-baris `SettingsRow` dengan pemisah berinset (gaya
/// pengaturan/akun). Radius 16, border tipis.
class ListTileCard extends StatelessWidget {
  const ListTileCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: t.borderSubtle),
        boxShadow: t.e1,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brCard,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpace.s16 + 40 + AppSpace.s12,
                    color: t.borderSubtle,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris pengaturan: ikon di kotak lembut, judul, subjudul, trailing (default
/// chevron bila `onTap` ada). `destructive` memakai warna bahaya.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = destructive ? t.danger : t.primary;
    final bg = destructive ? t.dangerContainer : t.primaryContainer;
    final end =
        trailing ??
        (onTap == null
            ? null
            : Icon(LucideIcons.chevronRight, size: 20, color: t.textSubtle));
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: MergeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s16,
              vertical: AppSpace.s12,
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: SizedBox.square(
                      dimension: 40,
                      child: Icon(icon, size: 20, color: fg),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: destructive ? t.danger : t.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: context.text.bodySm.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (end != null) ...[const SizedBox(width: AppSpace.s8), end],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
