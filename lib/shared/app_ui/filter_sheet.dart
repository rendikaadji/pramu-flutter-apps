import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';
import 'app_icon_button.dart';

/// Kerangka sheet filter bawah: judul + tombol tutup, konten (menggulir), dan
/// footer Reset / Terapkan. Isi (chip, slider rentang, dst.) disuplai pemanggil;
/// bungkus `StatefulBuilder` bila isi punya state sendiri.
class FilterSheet extends StatelessWidget {
  const FilterSheet({
    super.key,
    required this.title,
    required this.child,
    required this.onApply,
    this.onReset,
    this.applyLabel = 'Terapkan',
    this.resetLabel = 'Reset',
  });

  final String title;
  final Widget child;
  final VoidCallback onApply;
  final VoidCallback? onReset;
  final String applyLabel, resetLabel;

  /// Tampilkan sebagai modal bottom sheet (radius 24, handle dari tema).
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
    required VoidCallback onApply,
    VoidCallback? onReset,
    String applyLabel = 'Terapkan',
    String resetLabel = 'Reset',
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => FilterSheet(
      title: title,
      onApply: () {
        Navigator.pop(ctx);
        onApply();
      },
      onReset: onReset,
      applyLabel: applyLabel,
      resetLabel: resetLabel,
      child: Builder(builder: builder),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpace.s20),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: context.text.h2),
                  ),
                ),
                AppIconButton(
                  icon: LucideIcons.x,
                  label: 'Tutup',
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: AppSpace.s4),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s20,
                AppSpace.s8,
                AppSpace.s20,
                AppSpace.s16,
              ),
              child: child,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s16),
              child: Row(
                children: [
                  if (onReset != null) ...[
                    Expanded(
                      child: AppButton(
                        label: resetLabel,
                        variant: AppButtonVariant.secondary,
                        onPressed: onReset,
                      ),
                    ),
                    const SizedBox(width: AppSpace.s12),
                  ],
                  Expanded(
                    flex: 2,
                    child: AppButton(label: applyLabel, onPressed: onApply),
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
