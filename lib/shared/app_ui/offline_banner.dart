import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

/// Banner tipis di atas layar saat offline. `updatedAt` = teks siap tampil
/// ("diperbarui 14.02") untuk data tersimpan terakhir.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.updatedAt});

  final String? updatedAt;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final msg =
        'Anda sedang offline. Beberapa fitur tidak tersedia.'
        '${updatedAt == null ? '' : ' Data $updatedAt.'}';
    return Semantics(
      liveRegion: true,
      container: true,
      child: ColoredBox(
        color: t.warningContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s16,
            vertical: AppSpace.s12,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(LucideIcons.wifiOff, size: 20, color: t.warning),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Text(
                  msg,
                  style: context.text.bodySm.copyWith(
                    color: t.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
