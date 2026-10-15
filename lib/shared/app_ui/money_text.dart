import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum MoneySize { hero, body, small }

/// Nominal dalam mono tabular (angka sejajar). Menerima String yang SUDAH
/// terformat (mis. `Rp1.050.000`); pemformatan ada di core/money.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.size = MoneySize.body,
    this.color,
    this.textAlign,
  });

  final String amount;
  final MoneySize size;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final (s, lh, w) = switch (size) {
      MoneySize.hero => (32.0, 40.0, FontWeight.w600),
      MoneySize.body => (16.0, 24.0, FontWeight.w600),
      MoneySize.small => (14.0, 20.0, FontWeight.w500),
    };
    return Text(
      amount,
      textAlign: textAlign,
      style: AppText.mono(
        size: s,
        lineHeight: lh,
        weight: w,
        color: color ?? context.tokens.textPrimary,
      ),
    );
  }
}
