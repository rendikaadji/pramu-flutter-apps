import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';
import 'illustrations/illustrations.dart';

/// Layar/blok sukses: ilustrasi di tengah, judul, subjudul, 1 tombol utama dan
/// (opsional) 1 tautan sekunder. Menggulir bila skala teks besar.
class SuccessView extends StatelessWidget {
  const SuccessView({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.illustration,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  /// Default `SuccessIllustration`.
  final Widget? illustration;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                illustration ?? const SuccessIllustration(),
                const SizedBox(height: AppSpace.s24),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    title,
                    style: context.text.h1,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  message,
                  style: context.text.body.copyWith(color: t.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpace.s32),
                AppButton(label: actionLabel, large: true, onPressed: onAction),
                if (secondaryLabel != null) ...[
                  const SizedBox(height: AppSpace.s8),
                  AppButton(
                    label: secondaryLabel!,
                    variant: AppButtonVariant.text,
                    onPressed: onSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
