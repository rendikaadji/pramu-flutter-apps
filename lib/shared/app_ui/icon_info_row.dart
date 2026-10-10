import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Baris info: ikon redup 18dp + teks. Ikon dekoratif (teks tetap dibacakan).
class IconInfoRow extends StatelessWidget {
  const IconInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.small = false,
  });

  final IconData icon;
  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = small ? context.text.bodySm : context.text.body;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: ExcludeSemantics(
            child: Icon(icon, size: 18, color: t.textMuted),
          ),
        ),
        const SizedBox(width: AppSpace.s8),
        Expanded(
          child: Text(
            text,
            style: small ? style.copyWith(color: t.textMuted) : style,
          ),
        ),
      ],
    );
  }
}
