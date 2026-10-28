import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

/// Catatan privasi berikon gembok, mis. "Nomor disembunyikan sampai kontrak dibuat
/// dilakukan, demi keamanan Anda." Bila `onTap` diisi, jadi penjelas yang bisa diketuk.
class PrivacyNote extends StatelessWidget {
  const PrivacyNote(this.text, {super.key, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final body = Padding(
      padding: const EdgeInsets.all(AppSpace.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(LucideIcons.lock, size: 20, color: t.textMuted),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Text(
              text,
              style: context.text.bodySm.copyWith(color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
    return Material(
      color: t.sunken,
      borderRadius: AppRadius.brSm,
      child: onTap == null
          ? body
          : InkWell(onTap: onTap, borderRadius: AppRadius.brSm, child: body),
    );
  }
}
