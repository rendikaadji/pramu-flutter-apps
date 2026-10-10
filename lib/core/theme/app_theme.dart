import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_text.dart';
import 'app_tokens.dart';

export 'app_text.dart';
export 'app_tokens.dart';

/// Tema Material 3 biru langit (terang, bersih, airy). ColorScheme dibangun manual dari token
/// (bukan fromSeed). Pakai `AppTheme.light()` / `AppTheme.dark()`.
abstract final class AppTheme {
  static ThemeData light() => _build(AppTokens.light);
  static ThemeData dark() => _build(AppTokens.dark);

  static OutlineInputBorder outline(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: AppRadius.brInput,
        borderSide: BorderSide(color: color, width: width),
      );

  static ThemeData _build(AppTokens t) {
    final dark = t.isDark;
    final scheme = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: t.primary,
      onPrimary: t.onPrimary,
      primaryContainer: t.primaryContainer,
      onPrimaryContainer: t.primary,
      secondary: t.accent,
      onSecondary: t.onAccent,
      secondaryContainer: t.accentContainer,
      onSecondaryContainer: t.accent,
      error: t.danger,
      onError: t.onDanger,
      errorContainer: t.dangerContainer,
      onErrorContainer: t.danger,
      surface: t.surface,
      onSurface: t.textPrimary,
      onSurfaceVariant: t.textMuted,
      outline: t.borderStrong,
      outlineVariant: t.borderSubtle,
      shadow: Colors.black,
      scrim: t.scrim,
      inverseSurface: t.textPrimary,
      onInverseSurface: t.canvas,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: t.surface,
      surfaceContainerLow: t.surface,
      surfaceContainer: t.sunken,
      surfaceContainerHigh: t.raised,
      surfaceContainerHighest: t.sunken,
    );
    final text = AppText.theme(t);
    const none = Colors.transparent;
    final btnShape = RoundedRectangleBorder(borderRadius: AppRadius.brButton);
    final btnText = text.body.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: .1,
    );
    ButtonStyle btn() => ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, AppSpace.tap)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      shape: WidgetStatePropertyAll(btnShape),
      textStyle: WidgetStatePropertyAll(btnText),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    // Warna kontras terbalik untuk snackbar (latar = textPrimary).
    final inverse = dark ? AppTokens.light : AppTokens.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      extensions: [t],
      scaffoldBackgroundColor: t.canvas,
      canvasColor: t.canvas,
      textTheme: text,
      primaryTextTheme: text,
      splashFactory: InkRipple.splashFactory,
      highlightColor: none,
      focusColor: t.focusRing.withValues(alpha: .16),
      iconTheme: IconThemeData(color: t.textPrimary, size: 24),
      dividerTheme: DividerThemeData(
        color: t.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _ReduceMotionTransitions(
            PredictiveBackPageTransitionsBuilder(),
          ),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      filledButtonTheme: FilledButtonThemeData(style: btn()),
      elevatedButtonTheme: ElevatedButtonThemeData(style: btn()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: btn().copyWith(
          side: WidgetStatePropertyAll(BorderSide(color: t.borderStrong)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: btn()),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSpace.tap),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: text.body.copyWith(color: t.textSubtle),
        prefixIconColor: t.textMuted,
        suffixIconColor: t.textMuted,
        errorStyle: text.bodySm.copyWith(color: t.danger),
        prefixStyle: AppText.mono(size: 16, lineHeight: 24, color: t.textMuted),
        border: outline(t.borderStrong),
        enabledBorder: outline(t.borderStrong),
        focusedBorder: outline(t.focusRing, 2),
        errorBorder: outline(t.danger, 1.5),
        focusedErrorBorder: outline(t.danger, 2),
        disabledBorder: outline(t.borderSubtle),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: none,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brCard,
          side: BorderSide(color: t.borderSubtle),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.sunken,
        selectedColor: t.primaryContainer,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: text.bodySm.copyWith(
          color: t.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        checkmarkColor: t.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: none,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: none,
        centerTitle: false,
        titleTextStyle: text.h2.copyWith(color: t.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: none,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: t.surface,
        surfaceTintColor: none,
        indicatorColor: t.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.bodySm.copyWith(
            color: s.contains(WidgetState.selected)
                ? t.textPrimary
                : t.textMuted,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected) ? t.primary : t.textMuted,
          ),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: t.danger,
        textColor: t.onDanger,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.raised,
        surfaceTintColor: none,
        elevation: dark ? 0 : 8,
        shadowColor: t.e3.isEmpty ? null : t.e3.first.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: dark ? BorderSide(color: t.borderSubtle) : BorderSide.none,
        ),
        titleTextStyle: text.h2,
        contentTextStyle: text.body,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.raised,
        modalBackgroundColor: t.raised,
        surfaceTintColor: none,
        modalBarrierColor: t.scrim,
        elevation: dark ? 0 : 8,
        showDragHandle: true,
        dragHandleColor: t.borderStrong,
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLgTop),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.textPrimary,
        contentTextStyle: text.body.copyWith(color: t.canvas),
        actionTextColor: inverse.primary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brInput),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: 56,
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: t.textMuted,
        textColor: t.textPrimary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: t.primary,
        inactiveTrackColor: t.primaryContainer,
        thumbColor: t.primary,
        overlayColor: t.primary.withValues(alpha: .12),
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 11,
        ),
        trackHeight: 6,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.primary,
        linearTrackColor: t.borderSubtle,
        circularTrackColor: none,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.primary : none,
        ),
        checkColor: WidgetStatePropertyAll(t.onPrimary),
        side: BorderSide(color: t.borderStrong, width: 2),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brXs),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.primary : t.borderStrong,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.onPrimary : t.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.primary : t.sunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? none : t.borderStrong,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.primary,
        selectionColor: t.primary.withValues(alpha: .28),
        selectionHandleColor: t.primary,
      ),
    );
  }
}

/// Transisi halaman Android dimatikan saat reduce motion. iOS tetap Cupertino
/// (swipe-back harus tetap berfungsi).
class _ReduceMotionTransitions extends PageTransitionsBuilder {
  const _ReduceMotionTransitions(this.inner);
  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : inner.buildTransitions<T>(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}

extension AppThemeContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  TextTheme get text => Theme.of(this).textTheme;

  Color roleColor(AppRole role) => tokens.roleColor(role);
  Color roleContainer(AppRole role) => tokens.roleContainer(role);

  /// Durasi motion yang menghormati reduce motion sistem.
  Duration motion(Duration d) =>
      MediaQuery.disableAnimationsOf(this) ? Duration.zero : d;
}
