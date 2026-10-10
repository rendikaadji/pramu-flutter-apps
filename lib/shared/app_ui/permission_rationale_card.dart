import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Penjelasan izin OS. Dua pemakaian:
/// - sebelum prompt OS (pre-permission): tombol utama "Izinkan kamera" + "Nanti dulu";
/// - setelah ditolak (`denied: true`): kartu peringatan, tombol "Buka Pengaturan" +
///   alternatif (mis. "Pilih dari galeri").
class PermissionRationaleCard extends StatelessWidget {
  const PermissionRationaleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.denied = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool denied;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tint = denied ? t.warning : t.primary;
    return AppCard(
      color: denied ? t.warningContainer : null,
      borderColor: denied ? t.warning.withValues(alpha: .4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icon, size: 32, color: tint)),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.h3),
                    const SizedBox(height: AppSpace.s4),
                    Text(message, style: context.text.body),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(label: primaryLabel, onPressed: onPrimary),
          if (secondaryLabel != null) ...[
            const SizedBox(height: AppSpace.s8),
            AppButton(
              label: secondaryLabel!,
              variant: AppButtonVariant.secondary,
              onPressed: onSecondary,
            ),
          ],
        ],
      ),
    );
  }
}
