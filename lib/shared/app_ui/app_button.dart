import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, tonal, danger, text }

/// Tombol 48dp (large: 52). `loading` menampilkan spinner, menjaga lebar, dan
/// menonaktifkan ketukan (cegah ganda ketuk).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.large = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (t.primary, t.onPrimary, null),
      AppButtonVariant.secondary => (
        t.surface,
        t.primary,
        t.primary.withValues(alpha: .45),
      ),
      AppButtonVariant.tonal => (t.primaryContainer, t.primary, null),
      AppButtonVariant.danger => (t.danger, t.onDanger, null),
      AppButtonVariant.text => (Colors.transparent, t.primary, null),
    };
    final dim = onPressed == null; // loading tetap berwarna aktif
    final isText = variant == AppButtonVariant.text;
    final bgC = dim && !isText ? t.borderSubtle : bg;
    final fgC = dim ? t.textSubtle : fg;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(expand ? double.infinity : 64, large ? 52 : AppSpace.tap),
      ),
      backgroundColor: WidgetStatePropertyAll(bgC),
      foregroundColor: WidgetStatePropertyAll(fgC),
      overlayColor: WidgetStatePropertyAll(fgC.withValues(alpha: .12)),
      side: border == null
          ? null
          : WidgetStatePropertyAll(
              BorderSide(color: dim ? t.borderSubtle : border),
            ),
    );
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpace.s8),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    final child = Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: loading ? 0 : 1, child: content),
        if (loading)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fgC,
              semanticsLabel: '$label, sedang diproses',
            ),
          ),
      ],
    );
    final tap = loading || onPressed == null
        ? null
        : () {
            // Haptic ringan pada aksi utama saja.
            if (variant == AppButtonVariant.primary ||
                variant == AppButtonVariant.danger) {
              HapticFeedback.lightImpact();
            }
            onPressed!();
          };
    return isText
        ? TextButton(onPressed: tap, style: style, child: child)
        : FilledButton(onPressed: tap, style: style, child: child);
  }
}
