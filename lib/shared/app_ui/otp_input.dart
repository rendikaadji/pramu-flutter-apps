import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pramu_apps/core/test_keys.dart';

import '../../core/theme/app_theme.dart';
import 'field_error_text.dart';

/// Kode OTP N kotak (default 6). Satu field tersembunyi menampung ketikan, sehingga
/// auto-advance, hapus mundur, tempel, dan autofill SMS (`oneTimeCode`) bekerja dan
/// screen reader hanya melihat satu field berlabel.
///
/// Saat `errorText` berubah menjadi non-null: kotak digoyang, perangkat bergetar, isian
/// dikosongkan, dan pesan tampil. Hitung mundur/kirim ulang ada di layar pemakai.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.autofocus = true,
  });

  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;
  final bool autofocus;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  late final _shake = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  @override
  void didUpdateWidget(OtpInput old) {
    super.didUpdateWidget(old);
    if (widget.errorText != null && widget.errorText != old.errorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        HapticFeedback.vibrate();
        _ctrl.clear();
        if (!MediaQuery.disableAnimationsOf(context)) _shake.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _changed(String v) {
    widget.onChanged?.call(v);
    if (v.length == widget.length) widget.onCompleted?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasError = widget.errorText != null;
    final boxes = ListenableBuilder(
      listenable: Listenable.merge([_ctrl, _focus]),
      builder: (_, _) {
        final text = _ctrl.text;
        final active = _focus.hasFocus
            ? math.min(text.length, widget.length - 1)
            : -1;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.s8),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 52),
                  child: Container(
                    key: K.otpBox(i),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: AppRadius.brSm,
                      border: Border.all(
                        color: hasError
                            ? t.danger
                            : i == active
                            ? t.focusRing
                            : t.borderStrong,
                        width: i == active || hasError ? 2 : 1,
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        i < text.length ? text[i] : '',
                        style: AppText.mono(
                          size: 24,
                          lineHeight: 32,
                          weight: FontWeight.w600,
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _shake,
          builder: (_, child) => Transform.translate(
            offset: Offset(
              math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value),
              0,
            ),
            child: child,
          ),
          child: Semantics(
            label: 'Kode OTP, ${widget.length} digit',
            textField: true,
            child: Stack(
              children: [
                ExcludeSemantics(child: boxes),
                Positioned.fill(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    autofocus: widget.autofocus,
                    enabled: widget.enabled,
                    expands: true,
                    maxLines: null,
                    keyboardType: TextInputType.number,
                    enableSuggestions: false,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    showCursor: false,
                    enableInteractiveSelection: false,
                    style: const TextStyle(color: Colors.transparent),
                    cursorColor: Colors.transparent,
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      counterText: '',
                    ),
                    onChanged: _changed,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpace.s8),
          FieldErrorText(widget.errorText!),
        ],
      ],
    );
  }
}
