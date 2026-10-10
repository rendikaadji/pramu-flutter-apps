import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'status_chip.dart';

/// Visual hasil/status layar penuh: lencana bulat bertinta nada (ikon + teks + warna),
/// judul, dan penjelasan. Dipakai status pembayaran, hasil pencairan, status laporan.
class StatusHeroPanel extends StatelessWidget {
  const StatusHeroPanel({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.message,
    this.footer,
  });

  final IconData icon;
  final StatusTone tone;
  final String title;
  final String message;

  /// Isi tambahan di bawah penjelasan (mis. ringkasan nominal).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = tone.fg(t);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tone.bg(t),
              shape: BoxShape.circle,
              border: Border.all(color: fg.withValues(alpha: .45), width: 1.5),
            ),
            child: SizedBox.square(
              dimension: 88,
              child: Icon(icon, size: 40, color: fg),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s20),
        Semantics(
          header: true,
          child: Text(
            title,
            style: context.text.h2,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          message,
          style: context.text.body.copyWith(color: t.textMuted),
          textAlign: TextAlign.center,
        ),
        if (footer != null) ...[const SizedBox(height: AppSpace.s20), footer!],
      ],
    );
  }
}
