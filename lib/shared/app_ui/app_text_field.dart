import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import 'app_icon_button.dart';
import 'field_error_text.dart';

/// Field dengan label di atas (tidak hilang saat fokus), bantuan/error di bawah.
///
/// - `obscure`: sandi/nomor sensitif, ada tombol mata.
/// - `sensitive`: matikan saran, koreksi otomatis, dan autofill (mis. nomor KTP);
///   otomatis aktif bila `obscure`.
/// - `prefixText`: mis. `Rp` atau `+62`. Mask/format lewat `inputFormatters`.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.prefixText,
    this.prefixIcon,
    this.maxLength,
    this.maxLines = 1,
    this.obscure = false,
    this.sensitive = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? helper;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final String? prefixText;

  /// Ikon di depan field (gaya referensi: ikon + outline radius 12).
  final IconData? prefixIcon;
  final int? maxLength;
  final int maxLines;
  final bool obscure;
  final bool sensitive;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final error = widget.errorText;
    final secret = widget.obscure || widget.sensitive;
    final errorOutline = error == null ? null : AppTheme.outline(t.danger, 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: context.text.label.copyWith(color: t.textPrimary),
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Semantics(
          label: widget.label,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            obscureText: _hidden,
            obscuringCharacter: '•',
            autocorrect: !secret,
            enableSuggestions: !secret,
            enableIMEPersonalizedLearning: !secret,
            autofillHints: widget.sensitive ? null : widget.autofillHints,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            maxLength: widget.maxLength,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            style: context.text.body,
            decoration: InputDecoration(
              hintText: widget.hint,
              counterText: '',
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Icon(widget.prefixIcon, size: 20),
              prefixText: widget.prefixText == null
                  ? null
                  : '${widget.prefixText} ',
              enabledBorder: errorOutline,
              focusedBorder: error == null
                  ? null
                  : AppTheme.outline(t.danger, 2),
              suffixIcon: widget.obscure
                  ? AppIconButton(
                      icon: _hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                      label: _hidden ? 'Tampilkan isian' : 'Sembunyikan isian',
                      onPressed: () => setState(() => _hidden = !_hidden),
                    )
                  : null,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpace.s4),
          FieldErrorText(error),
        ] else if (widget.helper != null) ...[
          const SizedBox(height: AppSpace.s4),
          Text(widget.helper!, style: context.text.bodySm),
        ],
      ],
    );
  }
}
