import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Glow gradien biru muda lembut di atas layar (area header). Dekoratif, tidak
/// menangkap sentuhan, dan cukup pucat agar teks `textPrimary`/`textMuted` tetap
/// >= 4.5:1. Dipakai lewat `AppScaffold(glow: true)` atau di-`Stack` sendiri.
class HeaderGlow extends StatelessWidget {
  const HeaderGlow({super.key, this.height = 300});

  final double height;

  static double _alpha(AppTokens t) => t.isDark ? .4 : .32;
  static Color _radial(AppTokens t) => t.isDark ? t.glow : t.primaryBright;

  /// Warna latar paling pekat yang bisa berada di bawah teks (untuk test kontras).
  static Color peak(AppTokens t) => Color.alphaBlend(
    _radial(t).withValues(alpha: _alpha(t) * .5),
    Color.alphaBlend(t.glow.withValues(alpha: _alpha(t)), t.canvas),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final a = _alpha(t);
    Color g(double k) => t.glow.withValues(alpha: a * k);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [g(1), g(.35), g(0)],
                    stops: const [0, .55, 1],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.0, -1.1),
                    radius: .9,
                    colors: [
                      _radial(t).withValues(alpha: a * .5),
                      g(0),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.1, -.7),
                    radius: .7,
                    colors: [
                      _radial(t).withValues(alpha: a * .35),
                      g(0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
