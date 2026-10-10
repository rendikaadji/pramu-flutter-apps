import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';

/// Kosong: ikon garis 48dp + judul 1 baris + penjelasan 1 kalimat + 1 tombol aksi.
/// Bedakan "belum ada" (ajak membuat) vs "hasil kosong karena filter" (tombol Reset).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.sunken,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.borderSubtle),
                ),
                child: SizedBox.square(
                  dimension: 72,
                  child: Icon(icon, size: 32, color: t.textMuted),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s16),
            Semantics(
              header: true,
              child: Text(
                title,
                style: context.text.h3,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpace.s8),
            Text(
              message,
              style: context.text.body.copyWith(color: t.textMuted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpace.s24),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
