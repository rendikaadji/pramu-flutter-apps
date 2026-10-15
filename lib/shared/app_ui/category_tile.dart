import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Ubin kategori: ikon di kotak lembut + label (maks 2 baris). Untuk Grid/Wrap.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Warna kotak dan ikon; default biru (primaryContainer / primary).
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: AppRadius.brCard,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color ?? t.primaryContainer,
                  borderRadius: AppRadius.brCard,
                ),
                child: SizedBox.square(
                  dimension: 56,
                  child: Icon(icon, size: 26, color: iconColor ?? t.primary),
                ),
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySm.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
