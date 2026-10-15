import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'money_text.dart';

class FeeRow {
  const FeeRow(this.label, this.amount, {this.total = false});

  final String label;

  /// Nominal siap tampil, mis. "Rp1.000.000" atau "-Rp50.000".
  final String amount;

  /// Baris total/"Anda terima": ditebalkan dan diberi garis pemisah di atasnya.
  final bool total;
}

/// Rincian nominal · fee · total (bayar & terima). Selalu tampil sebelum dan sesudah bayar.
class FeeBreakdown extends StatelessWidget {
  const FeeBreakdown({super.key, required this.rows});

  final List<FeeRow> rows;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        for (final r in rows) ...[
          if (r.total) Divider(color: t.borderStrong),
          Semantics(
            container: true,
            label: '${r.label}: ${r.amount}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      r.label,
                      style: r.total
                          ? context.text.h3
                          : context.text.body.copyWith(color: t.textMuted),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s12),
                  MoneyText(r.amount),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
