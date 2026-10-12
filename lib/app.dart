import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/router/app_router.dart';
import 'package:pramu_apps/core/theme/app_theme.dart';
import 'package:pramu_apps/core/theme_mode_controller.dart';
import 'package:pramu_apps/features/notification/data/push_providers.dart';

class PramuApp extends ConsumerWidget {
  const PramuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushTokenSyncProvider);
    return MaterialApp.router(
      title: 'Pramu',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      // Status/navigation bar transparan: tanpa ini layar tanpa AppBar punya
      // pita warna beda setinggi status bar yang "membelah" latar.
      builder: (context, child) {
        final icons = Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: icons,
            statusBarBrightness: Theme.of(context).brightness,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: icons,
            systemNavigationBarContrastEnforced: false,
          ),
          child: child!,
        );
      },
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
