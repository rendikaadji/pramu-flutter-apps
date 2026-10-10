import 'package:flutter/material.dart';

/// Peran aktif pengguna. Pencari = primary (indigo), Asisten = accent (soga).
enum AppRole {
  seeker,
  assistant;

  String get label => this == seeker ? 'Pencari' : 'Asisten';
}

/// Spacing basis 4 (Brief §3.3).
abstract final class AppSpace {
  static const double s0 = 0,
      s2 = 2,
      s4 = 4,
      s8 = 8,
      s12 = 12,
      s16 = 16,
      s20 = 20,
      s24 = 24,
      s32 = 32,
      s40 = 40,
      s48 = 48,
      s64 = 64;

  /// Target sentuh minimum (dp).
  static const double tap = 48;

  /// Lebar konten maksimum di layar besar.
  static const double maxContent = 600;
}

abstract final class AppRadius {
  static const double xs = 4, sm = 8, md = 12, lg = 20;
  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLgTop = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
}

/// Motion (Brief §3.4). Hanya transform/opacity. Bungkus dengan `context.motion(d)`
/// agar hormati reduce motion.
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);
  static const Curve standard = Cubic(.2, 0, 0, 1);
  static const Curve enter = Cubic(.05, .7, .1, 1);
  static const Curve exit = Cubic(.3, 0, .8, .15);
}

/// Token warna + elevasi (Brief §3.1). Nilai identik dengan tabel; kolom `on*`
/// untuk success/warning tidak ada karena status chip memakai warna di atas container.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.isDark,
    required this.canvas,
    required this.surface,
    required this.sunken,
    required this.raised,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textMuted,
    required this.textSubtle,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.accent,
    required this.accentContainer,
    required this.onAccent,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDanger,
    required this.focusRing,
    required this.scrim,
    required this.e1,
    required this.e2,
    required this.e3,
  });

  final bool isDark;
  final Color canvas, surface, sunken, raised;
  final Color borderSubtle, borderStrong;
  final Color textPrimary, textMuted, textSubtle;
  final Color primary, primaryContainer, onPrimary;
  final Color accent, accentContainer, onAccent;
  final Color success, successContainer;
  final Color warning, warningContainer;
  final Color danger, dangerContainer, onDanger;
  final Color focusRing, scrim;

  /// e1 kartu, e2 sheet/menu, e3 dialog. Dark: kosong (permukaan lebih terang).
  final List<BoxShadow> e1, e2, e3;

  Color roleColor(AppRole r) => r == AppRole.seeker ? primary : accent;
  Color roleContainer(AppRole r) =>
      r == AppRole.seeker ? primaryContainer : accentContainer;

  static const light = AppTokens(
    isDark: false,
    canvas: Color(0xFFFAF7F2),
    surface: Color(0xFFFFFFFF),
    sunken: Color(0xFFF3EEE6),
    raised: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFE2D9CC),
    borderStrong: Color(0xFF8C8070),
    textPrimary: Color(0xFF1F1B16),
    textMuted: Color(0xFF5A5146),
    textSubtle: Color(0xFF6F6558),
    primary: Color(0xFF244C7C),
    primaryContainer: Color(0xFFE4ECF7),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF9A4E1C),
    accentContainer: Color(0xFFF8E9DC),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF1B6E45),
    successContainer: Color(0xFFE3F2EA),
    warning: Color(0xFF8A5200),
    warningContainer: Color(0xFFFFF1D6),
    danger: Color(0xFFB3261E),
    dangerContainer: Color(0xFFFBE5E3),
    onDanger: Color(0xFFFFFFFF),
    focusRing: Color(0xFF244C7C),
    scrim: Color(0x7A1F1B16), // rgba(31,27,22,.48)
    e1: [
      BoxShadow(color: Color(0x141F1B16), blurRadius: 3, offset: Offset(0, 1)),
    ],
    e2: [
      BoxShadow(color: Color(0x1F1F1B16), blurRadius: 12, offset: Offset(0, 4)),
    ],
    e3: [
      BoxShadow(color: Color(0x291F1B16), blurRadius: 24, offset: Offset(0, 8)),
    ],
  );

  static const dark = AppTokens(
    isDark: true,
    canvas: Color(0xFF15130F),
    surface: Color(0xFF1E1B16),
    sunken: Color(0xFF100E0B),
    raised: Color(0xFF27231D),
    borderSubtle: Color(0xFF3A342B),
    borderStrong: Color(0xFF7A6F60),
    textPrimary: Color(0xFFF2EDE4),
    textMuted: Color(0xFFBDB3A4),
    textSubtle: Color(0xFFA39989),
    primary: Color(0xFF9DBDEB),
    primaryContainer: Color(0xFF1F3350),
    onPrimary: Color(0xFF0F2542),
    accent: Color(0xFFE8A472),
    accentContainer: Color(0xFF3A2616),
    onAccent: Color(0xFF2B1708),
    success: Color(0xFF6FCB9A),
    successContainer: Color(0xFF143323),
    warning: Color(0xFFF0B95B),
    warningContainer: Color(0xFF3A2B0E),
    danger: Color(0xFFFF9A92),
    dangerContainer: Color(0xFF4A1A17),
    onDanger: Color(0xFF3A0B08),
    focusRing: Color(0xFF9DBDEB),
    scrim: Color(0xA3000000), // rgba(0,0,0,.64)
    e1: [],
    e2: [],
    e3: [],
  );

  /// Token bersifat konstan per tema; tidak ada yang di-override per widget.
  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      isDark: t < .5 ? isDark : other.isDark,
      canvas: c(canvas, other.canvas),
      surface: c(surface, other.surface),
      sunken: c(sunken, other.sunken),
      raised: c(raised, other.raised),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      borderStrong: c(borderStrong, other.borderStrong),
      textPrimary: c(textPrimary, other.textPrimary),
      textMuted: c(textMuted, other.textMuted),
      textSubtle: c(textSubtle, other.textSubtle),
      primary: c(primary, other.primary),
      primaryContainer: c(primaryContainer, other.primaryContainer),
      onPrimary: c(onPrimary, other.onPrimary),
      accent: c(accent, other.accent),
      accentContainer: c(accentContainer, other.accentContainer),
      onAccent: c(onAccent, other.onAccent),
      success: c(success, other.success),
      successContainer: c(successContainer, other.successContainer),
      warning: c(warning, other.warning),
      warningContainer: c(warningContainer, other.warningContainer),
      danger: c(danger, other.danger),
      dangerContainer: c(dangerContainer, other.dangerContainer),
      onDanger: c(onDanger, other.onDanger),
      focusRing: c(focusRing, other.focusRing),
      scrim: c(scrim, other.scrim),
      e1: t < .5 ? e1 : other.e1,
      e2: t < .5 ? e2 : other.e2,
      e3: t < .5 ? e3 : other.e3,
    );
  }
}
