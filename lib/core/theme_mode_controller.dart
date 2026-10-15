import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/providers.dart';

const _prefKey = 'theme_mode';

/// Tema Sistem/Terang/Gelap (M-24), tersimpan di SharedPreferences.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.read(prefsProvider).getString(_prefKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(prefsProvider).setString(_prefKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
