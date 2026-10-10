import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Satu bahasa kartu: border + e1, radius md. Jangan menyarang kartu di dalam kartu.
/// Bila `onTap` diisi, seluruh kartu satu target sentuh dan dibacakan sebagai satu item.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.s16),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.brMd,
      side: BorderSide(color: borderColor ?? t.borderSubtle),
    );
    final padded = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color ?? t.surface,
        shape: shape,
        shadows: t.e1,
      ),
      child: onTap == null
          ? padded
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                customBorder: shape,
                child: MergeSemantics(child: padded),
              ),
            ),
    );
  }
}
