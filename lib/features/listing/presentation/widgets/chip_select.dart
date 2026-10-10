import 'package:flutter/material.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Pilihan tunggal berbentuk chip. Ketuk pilihan aktif lagi untuk menghapus bila [clearable].
class ChipSelect<T> extends StatelessWidget {
  const ChipSelect({
    super.key,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.clearable = true,
  });

  final List<T> options;
  final String Function(T) labelOf;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final bool clearable;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.s8,
    runSpacing: AppSpace.s8,
    children: [
      for (final o in options)
        ChoiceChip(
          key: K.option(labelOf(o)),
          label: Text(labelOf(o)),
          selected: o == selected,
          onSelected: (on) => onChanged(on ? o : (clearable ? null : selected)),
        ),
    ],
  );
}
