import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import 'status_presets.dart';

enum StatusTone { neutral, info, success, warning, danger, accent }

extension StatusToneColors on StatusTone {
  Color fg(AppTokens t) => switch (this) {
    StatusTone.neutral => t.textMuted,
    StatusTone.info => t.primary,
    StatusTone.success => t.success,
    StatusTone.warning => t.warning,
    StatusTone.danger => t.danger,
    StatusTone.accent => t.accent,
  };

  Color bg(AppTokens t) => switch (this) {
    StatusTone.neutral => t.sunken,
    StatusTone.info => t.primaryContainer,
    StatusTone.success => t.successContainer,
    StatusTone.warning => t.warningContainer,
    StatusTone.danger => t.dangerContainer,
    StatusTone.accent => t.accentContainer,
  };

  IconData get icon => switch (this) {
    StatusTone.neutral => LucideIcons.circle,
    StatusTone.info => LucideIcons.info,
    StatusTone.success => LucideIcons.circleCheck,
    StatusTone.warning => LucideIcons.clock,
    StatusTone.danger => LucideIcons.circleX,
    StatusTone.accent => LucideIcons.badgeCheck,
  };
}

/// Chip status: ikon + teks + warna (status tidak pernah hanya warna).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  /// Dari kode status backend (peta Brief §9). `role` hanya memengaruhi label period.
  factory StatusChip.of(
    StatusDomain domain,
    String code, {
    AppRole role = AppRole.seeker,
    Key? key,
  }) {
    final p = statusPreset(domain, code, role);
    return StatusChip(key: key, label: p.label, tone: p.tone, icon: p.icon);
  }

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = tone.fg(t);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.bg(t),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        // Dark: hairline bernada agar container gelap tetap terbaca di kanvas.
        border: t.isDark ? Border.all(color: fg.withValues(alpha: .28)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s12,
          vertical: AppSpace.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon ?? tone.icon, size: 16, color: fg),
            ),
            const SizedBox(width: AppSpace.s4),
            Flexible(
              child: Text(
                label,
                style: context.text.bodySm.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
