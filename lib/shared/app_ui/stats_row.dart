import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class StatItem {
  const StatItem(this.value, this.label);

  final String value;
  final String label;
}

/// Baris statistik 2-4 angka di dalam kartu (profil: Selesai / Rating / Ulasan).
class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: t.borderSubtle),
        boxShadow: t.e1,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) VerticalDivider(width: 1, color: t.borderSubtle),
                Expanded(
                  child: MergeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.s4,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            items[i].value,
                            style: context.text.h2.copyWith(
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpace.s2),
                          Text(
                            items[i].label,
                            style: context.text.caption.copyWith(
                              color: t.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
