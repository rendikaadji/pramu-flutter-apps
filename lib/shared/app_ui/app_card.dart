import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Satu bahasa kartu: border tipis + e1 sangat halus, radius 16. Jangan menyarang kartu di dalam kartu.
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
      borderRadius: AppRadius.brCard,
      side: BorderSide(color: borderColor ?? t.borderSubtle),
    );
    final padded = Padding(padding: padding, child: child);
    // Penuh lebar bila lebar terbatas (Column start); di Row/Wrap tetap ikut isi.
    return LayoutBuilder(
      builder: (context, c) => SizedBox(
        width: c.hasBoundedWidth ? double.infinity : null,
        child: _frame(t, shape, padded),
      ),
    );
  }

  Widget _frame(AppTokens t, ShapeBorder shape, Widget padded) {
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
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
                customBorder: shape,
                child: MergeSemantics(child: padded),
              ),
            ),
    );
  }
}
