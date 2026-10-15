import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Progres wizard: "Langkah 2 dari 4" + segmen. `current` mulai dari 1. Maks 4 langkah per wizard.
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.current,
    required this.total,
    this.title,
  });

  final int current;
  final int total;

  /// Judul langkah aktif, mis. "Periode & budget".
  final String? title;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text =
        'Langkah $current dari $total${title == null ? '' : ': $title'}';
    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: context.text.label.copyWith(color: t.textMuted)),
          const SizedBox(height: AppSpace.s8),
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1) const SizedBox(width: AppSpace.s4),
                Expanded(
                  child: AnimatedContainer(
                    duration: context.motion(AppMotion.base),
                    curve: AppMotion.standard,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= current ? t.primary : t.borderSubtle,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
