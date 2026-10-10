import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import 'app_card.dart';

/// Kartu "Langkah berikutnya": satu tugas yang paling penting sekarang.
/// Tint mengikuti peran (Pencari indigo, Asisten soga).
class NextStepCard extends StatelessWidget {
  const NextStepCard({
    super.key,
    required this.title,
    this.message,
    this.onTap,
    this.role = AppRole.seeker,
  });

  final String title;
  final String? message;
  final VoidCallback? onTap;
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tint = t.roleColor(role);
    return AppCard(
      onTap: onTap,
      color: t.roleContainer(role),
      borderColor: tint.withValues(alpha: .4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Langkah berikutnya',
                  style: context.text.bodySm.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpace.s4),
                Text(title, style: context.text.h3),
                if (message != null) ...[
                  const SizedBox(height: AppSpace.s4),
                  Text(
                    message!,
                    style: context.text.body.copyWith(color: t.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: AppSpace.s12),
            Icon(LucideIcons.arrowRight, color: tint),
          ],
        ],
      ),
    );
  }
}
