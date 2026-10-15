import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

String _id(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// Rating ringkas untuk kartu daftar: satu bintang + angka + jumlah ulasan.
/// Lebih ringan dari lima bintang; bacaan layar sama dengan RatingStars.
class CompactRating extends StatelessWidget {
  const CompactRating({super.key, required this.value, required this.count});

  final double value;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = context.text.bodySm;
    return Semantics(
      label: 'Rating ${_id(value)} dari 5, $count ulasan',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.star, size: 16, color: t.accent),
          const SizedBox(width: AppSpace.s4),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _id(value),
                    style: s.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' ($count ulasan)',
                    style: s.copyWith(color: t.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
