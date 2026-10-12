import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Glow gradien biru muda lembut di atas layar (area header). Dekoratif, tidak
/// menangkap sentuhan, dan cukup pucat agar teks `textPrimary`/`textMuted` tetap
/// >= 4.5:1. Dipakai lewat `AppScaffold(glow: true)` atau di-`Stack` sendiri.
class HeaderGlow extends StatelessWidget {
  const HeaderGlow({super.key, this.height = 460});

  final double height;

  static const _n = 10;

  static double _alpha(AppTokens t) => t.isDark ? .16 : .24;
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
    // Fade berkurva halus (ease-out kuartik): turunan mendekati 0 di ujung,
    // jadi tidak ada tepi/kink yang tampak sebagai garis pembelah.
    final lin = <Color>[];
    final linStops = <double>[];
    for (var i = 0; i <= _n; i++) {
      final x = i / _n;
      linStops.add(x);
      lin.add(g(math.pow(1 - x, 2.6).toDouble()));
    }
    List<Color> radial(double k) => [
      for (var i = 0; i <= _n; i++)
        _radial(t)
            .withValues(alpha: a * k * math.pow(1 - i / _n, 2.2).toDouble()),
    ];
    final radStops = [for (var i = 0; i <= _n; i++) i / _n];
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
                    colors: lin,
                    stops: linStops,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.0, -1.1),
                    radius: .9,
                    colors: radial(.5),
                    stops: radStops,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.1, -.7),
                    radius: .7,
                    colors: radial(.35),
                    stops: radStops,
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
