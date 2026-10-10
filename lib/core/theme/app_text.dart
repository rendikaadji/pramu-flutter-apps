import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Nama keluarga font. File font dibundel lewat pubspec (lihat docs/10-Design-System-App.md);
/// selama belum terpasang, Flutter jatuh ke font sistem lewat fallback di bawah.
abstract final class AppFonts {
  static const display = 'Fraunces';
  static const ui = 'IBMPlexSans';
  static const mono = 'IBMPlexMono';

  static const displayFallback = ['Georgia', 'Noto Serif', 'serif'];
  static const uiFallback = ['Roboto', 'Noto Sans', 'Helvetica Neue', 'Arial'];
  static const monoFallback = ['Roboto Mono', 'Menlo', 'Consolas', 'monospace'];
}

/// Skala tipografi Brief §3.2 (sp / line-height).
abstract final class AppText {
  static TextStyle _ui(double s, double lh, FontWeight w) => TextStyle(
    fontFamily: AppFonts.ui,
    fontFamilyFallback: AppFonts.uiFallback,
    fontSize: s,
    height: lh / s,
    fontWeight: w,
  );

  static TextStyle _display(double s, double lh) => TextStyle(
    fontFamily: AppFonts.display,
    fontFamilyFallback: AppFonts.displayFallback,
    fontSize: s,
    height: lh / s,
    fontWeight: FontWeight.w600,
  );

  /// Mono tabular untuk uang, ID, kode OTP.
  static TextStyle mono({
    double size = 14,
    double lineHeight = 20,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) => TextStyle(
    fontFamily: AppFonts.mono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextTheme theme(AppTokens t) {
    final display = _display(32, 40); // display
    final h1 = _display(26, 34);
    final h2 = _ui(20, 28, FontWeight.w600);
    final h3 = _ui(18, 26, FontWeight.w600);
    final body = _ui(16, 24, FontWeight.w400);
    final bodySm = _ui(14, 20, FontWeight.w400);
    final label = _ui(14, 20, FontWeight.w500);
    final caption = _ui(12, 16, FontWeight.w400);
    return TextTheme(
          displayLarge: display,
          displayMedium: display,
          displaySmall: display,
          headlineLarge: h1,
          headlineMedium: h1,
          headlineSmall: h2,
          titleLarge: h2,
          titleMedium: h3,
          titleSmall: label,
          bodyLarge: body,
          bodyMedium: body,
          bodySmall: bodySm,
          labelLarge: label,
          labelMedium: label,
          labelSmall: caption,
        )
        .apply(bodyColor: t.textPrimary, displayColor: t.textPrimary)
        .copyWith(
          bodySmall: bodySm.copyWith(color: t.textMuted),
          labelSmall: caption.copyWith(color: t.textMuted),
        );
  }
}

/// Nama token tipografi (Brief §3.2) di atas TextTheme.
extension AppTextStyles on TextTheme {
  TextStyle get display => displayLarge!;
  TextStyle get h1 => headlineLarge!;
  TextStyle get h2 => titleLarge!;
  TextStyle get h3 => titleMedium!;
  TextStyle get body => bodyLarge!;
  TextStyle get bodySm => bodySmall!;
  TextStyle get label => labelLarge!;
  TextStyle get caption => labelSmall!;
}
