import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Kartu inline "Gagal memuat" + Coba lagi. Isi `message` dengan pesan Indonesia dari
/// server; `code` tampil kecil ("Kode: SRV_500").
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = 'Tidak dapat terhubung. Periksa sinyal Anda lalu coba lagi.',
    this.code,
    this.onRetry,
  });

  final String message;
  final String? code;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppCard(
      color: t.dangerContainer,
      borderColor: t.danger.withValues(alpha: .4),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.circleAlert, color: t.danger),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gagal memuat', style: context.text.h3),
                      const SizedBox(height: AppSpace.s4),
                      Text(message, style: context.text.body),
                      if (code != null) ...[
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          'Kode: $code',
                          style: context.text.caption.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpace.s16),
              AppButton(
                label: 'Coba lagi',
                icon: LucideIcons.refreshCw,
                variant: AppButtonVariant.secondary,
                onPressed: onRetry,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
