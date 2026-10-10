import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Snackbar untuk info/sukses ringan saja ("Sekarang sebagai Asisten").
/// Error kritis memakai FieldErrorText / ErrorState / ConfirmDialog, bukan snackbar.
abstract final class AppSnack {
  static void show(
    BuildContext context,
    String message, {
    bool success = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(
              success ? LucideIcons.circleCheck : LucideIcons.info,
              size: 20,
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
  }
}
