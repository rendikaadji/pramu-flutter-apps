import 'package:flutter/material.dart';

/// Peran aktif pengguna. Pencari = primary (indigo), Asisten = assistant (soga).
enum AppRole {
  seeker,
  assistant;

  String get label => this == seeker ? 'Pencari' : 'Pelamar';
}

/// Spacing basis 4.
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

  /// Peran semantik: kartu 16, tombol 14, input 12, sheet 24.
  static const double card = 16, button = 14, input = 12, sheet = 24;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brCard = BorderRadius.all(Radius.circular(card));
  static const BorderRadius brButton = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius brInput = BorderRadius.all(Radius.circular(input));
  static const BorderRadius brLgTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Motion. Hanya transform/opacity. Bungkus dengan `context.motion(d)`
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

/// Token warna + elevasi (docs/10 §2). Kertas hangat, tinta indigo, segel soga.
/// `primary` = isian tombol/teks (lulus AA dengan putih); biru cerah hanya lewat
/// `primaryBright`, gradien (`featured*`, `heroSoft*`), `glow` dan container.
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
    required this.assistant,
    required this.assistantContainer,
    required this.primaryBright,
    required this.featuredFrom,
    required this.featuredTo,
    required this.heroSoftFrom,
    required this.heroSoftTo,
    required this.glow,
    required this.illoSoft,
    required this.illoAccent,
    required this.illoInk,
    required this.illoPaper,
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

  /// Peran Asisten (teal) + container-nya.
  final Color assistant, assistantContainer;

  /// Biru cerah/pastel: hanya dekorasi (gradien, glow, ilustrasi), bukan teks.
  final Color primaryBright;

  /// Gradien FeaturedCard (teks putih; kedua ujung >= 4.5:1 dengan putih).
  final Color featuredFrom, featuredTo;

  /// Gradien HeroBannerCard (lembut, teks textPrimary).
  final Color heroSoftFrom, heroSoftTo;

  /// Warna glow header (diberi alpha di HeaderGlow).
  final Color glow;

  /// Palet ilustrasi: biru lembut, aksen oranye, tinta garis, kertas.
  final Color illoSoft, illoAccent, illoInk, illoPaper;

  /// e1 kartu, e2 sheet/menu, e3 dialog. Dark: kosong (permukaan lebih terang).
  final List<BoxShadow> e1, e2, e3;

  Color roleColor(AppRole r) => r == AppRole.seeker ? primary : assistant;
  Color roleContainer(AppRole r) =>
      r == AppRole.seeker ? primaryContainer : assistantContainer;

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
    textSubtle: Color(0xFF685E51),
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
    scrim: Color(0x7A1F1B16),
    assistant: Color(0xFF9A4E1C),
    assistantContainer: Color(0xFFF8E9DC),
    primaryBright: Color(0xFF5B86BD),
    featuredFrom: Color(0xFF16345A),
    featuredTo: Color(0xFF244C7C),
    heroSoftFrom: Color(0xFFE4ECF7),
    heroSoftTo: Color(0xFFF8E9DC),
    glow: Color(0xFFD3E1F3),
    illoSoft: Color(0xFFE4ECF7),
    illoAccent: Color(0xFFC9743A),
    illoInk: Color(0xFF16345A),
    illoPaper: Color(0xFFFFFFFF),
    e1: [
      BoxShadow(color: Color(0x141F1B16), blurRadius: 8, offset: Offset(0, 2)),
    ],
    e2: [
      BoxShadow(color: Color(0x1F1F1B16), blurRadius: 16, offset: Offset(0, 6)),
    ],
    e3: [
      BoxShadow(
        color: Color(0x291F1B16),
        blurRadius: 28,
        offset: Offset(0, 10),
      ),
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
    scrim: Color(0xA3000000),
    assistant: Color(0xFFE8A472),
    assistantContainer: Color(0xFF3A2616),
    primaryBright: Color(0xFF5B86BD),
    featuredFrom: Color(0xFF16345A),
    featuredTo: Color(0xFF2B5A93),
    heroSoftFrom: Color(0xFF1F3350),
    heroSoftTo: Color(0xFF3A2616),
    glow: Color(0xFF2A4A78),
    illoSoft: Color(0xFF1F3350),
    illoAccent: Color(0xFFE8A472),
    illoInk: Color(0xFF9DBDEB),
    illoPaper: Color(0xFF27231D),
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
      assistant: c(assistant, other.assistant),
      assistantContainer: c(assistantContainer, other.assistantContainer),
      primaryBright: c(primaryBright, other.primaryBright),
      featuredFrom: c(featuredFrom, other.featuredFrom),
      featuredTo: c(featuredTo, other.featuredTo),
      heroSoftFrom: c(heroSoftFrom, other.heroSoftFrom),
      heroSoftTo: c(heroSoftTo, other.heroSoftTo),
      glow: c(glow, other.glow),
      illoSoft: c(illoSoft, other.illoSoft),
      illoAccent: c(illoAccent, other.illoAccent),
      illoInk: c(illoInk, other.illoInk),
      illoPaper: c(illoPaper, other.illoPaper),
      e1: t < .5 ? e1 : other.e1,
      e2: t < .5 ? e2 : other.e2,
      e3: t < .5 ? e3 : other.e3,
    );
  }
}
