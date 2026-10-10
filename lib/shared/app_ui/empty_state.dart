import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';
import 'illustrations/illustrations.dart';

/// Kosong: ilustrasi flat + judul + penjelasan 1 kalimat + 1 tombol aksi.
/// Bedakan "belum ada" (ajak membuat) vs "hasil kosong karena filter" (tombol Reset).
/// `illustration` default `EmptyListIllustration`; bila diberikan hanya `icon`
/// (kompatibilitas lama) dan tanpa `illustration`, ilustrasi default dipakai
/// dan ikon tidak ditampilkan.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.illustration,
    this.compact = false,
  });

  /// Tidak lagi ditampilkan; dipertahankan agar pemanggil lama tetap valid.
  final IconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? illustration;

  /// Ilustrasi lebih kecil untuk blok di dalam daftar/tab.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ?? EmptyListIllustration(size: compact ? 132 : 180),
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
