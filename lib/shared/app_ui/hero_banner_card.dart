import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import 'illustrations/illustrations.dart';

/// Banner beranda: gradien biru muda lembut, judul, subjudul, CTA kecil, ilustrasi
/// di kanan (disembunyikan bila sempit). Seluruh kartu satu target sentuh.
class HeroBannerCard extends StatelessWidget {
  const HeroBannerCard({
    super.key,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onTap,
    this.illustration,
  });

  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onTap;

  /// Default `WelcomeIllustration`.
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(AppRadius.lg);
    final body = LayoutBuilder(
      builder: (context, c) {
        final showArt = c.maxWidth >= 300;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.h2),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpace.s4),
                    Text(
                      subtitle!,
                      style: context.text.bodySm.copyWith(color: t.textMuted),
                    ),
                  ],
                  if (ctaLabel != null) ...[
                    const SizedBox(height: AppSpace.s16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.primary,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s16,
                          vertical: AppSpace.s8,
                        ),
                        child: Text(
                          ctaLabel!,
                          style: context.text.label.copyWith(
                            color: t.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArt) ...[
              const SizedBox(width: AppSpace.s8),
              illustration ?? const WelcomeIllustration(size: 120),
            ],
          ],
        );
      },
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.heroSoftFrom, t.heroSoftTo],
        ),
        border: Border.all(color: t.primaryBright.withValues(alpha: .25)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s20),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}
