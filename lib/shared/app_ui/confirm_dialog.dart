import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Dialog konfirmasi adaptif (Material di Android, Cupertino di iOS).
/// `await ConfirmDialog.show(...)` -> true bila dikonfirmasi. Aksi destruktif:
/// `destructive: true` (tombol berwarna bahaya), tidak pernah lewat swipe.
abstract final class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Lanjutkan',
    String cancelLabel = 'Batal',
    bool destructive = false,
  }) async {
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            style: destructive
                ? TextButton.styleFrom(foregroundColor: ctx.tokens.danger)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}
