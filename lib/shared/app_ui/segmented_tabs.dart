import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Tab pil (Semua / Dilamar / ...). Terpilih = isian primer; lain = abu muda.
/// Menggulir horizontal bila label tidak muat (skala teks besar).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpace.s8),
            Semantics(
              button: true,
              selected: i == index,
              inMutuallyExclusiveGroup: true,
              label: labels[i],
              excludeSemantics: true,
              onTap: () => onChanged(i),
              child: Material(
                color: i == index ? t.primary : t.sunken,
                shape: StadiumBorder(
                  side: t.isDark && i != index
                      ? BorderSide(color: t.borderSubtle)
                      : BorderSide.none,
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () {
                    if (i != index) HapticFeedback.selectionClick();
                    onChanged(i);
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.s20,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          labels[i],
                          style: context.text.label.copyWith(
                            color: i == index ? t.onPrimary : t.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
