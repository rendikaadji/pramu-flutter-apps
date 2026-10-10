import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

/// Pesan error di bawah field: ikon + teks (bukan hanya warna). Dibacakan otomatis.
class FieldErrorText extends StatelessWidget {
  const FieldErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.circleAlert, size: 16, color: t.danger),
          ),
          const SizedBox(width: AppSpace.s4),
          Expanded(
            child: Text(
              message,
              style: context.text.bodySm.copyWith(color: t.danger),
            ),
          ),
        ],
      ),
    );
  }
}
