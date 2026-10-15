import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'money_text.dart';

/// Tarif/budget: nominal mono tebal + satuan redup ("/ bulanan"). Menerima String terformat.
class RateText extends StatelessWidget {
  const RateText(
    this.amount, {
    super.key,
    this.unit,
    this.size = MoneySize.body,
  });

  final String amount;

  /// Mis. "bulanan"; ditampilkan sebagai "/ bulanan".
  final String? unit;
  final MoneySize size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: AppSpace.s4,
      children: [
        MoneyText(amount, size: size),
        if (unit != null)
          Text(
            '/ $unit',
            style: context.text.bodySm.copyWith(color: t.textMuted),
          ),
      ],
    );
  }
}
