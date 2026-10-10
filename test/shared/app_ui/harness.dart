import 'package:flutter/material.dart';
import 'package:pramu_apps/core/theme/app_theme.dart';

/// Bungkus widget dengan tema aplikasi untuk test.
Widget host(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? AppTheme.dark() : AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);
