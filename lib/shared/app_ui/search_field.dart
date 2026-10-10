import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

/// Bar pencarian besar berikon (radius 14, tinggi 52). Dengan `onTap` ia menjadi
/// pintu masuk ke layar cari (read-only). `trailing` mis. tombol filter.
/// Batas memakai borderSubtle + bayangan tipis; ikon kaca pembesar dan hint
/// menjadi penanda utama kontrol.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.hint = 'Cari lowongan atau asisten',
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.trailing,
    this.autofocus = false,
  });

  final String hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Mengisi = mode pintu masuk (read-only).
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final border = OutlineInputBorder(
      borderRadius: AppRadius.brButton,
      borderSide: BorderSide(color: t.borderSubtle),
    );
    final field = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brButton,
        boxShadow: t.e1,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        readOnly: onTap != null,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: context.text.body,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(LucideIcons.search, size: 22),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s16,
            vertical: 16,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.brButton,
            borderSide: BorderSide(color: t.focusRing, width: 2),
          ),
        ),
      ),
    );
    if (trailing == null) return field;
    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: AppSpace.s12),
        trailing!,
      ],
    );
  }
}
