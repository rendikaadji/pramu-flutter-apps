import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/app.dart';
import 'package:pramu_apps/core/platform/sensitive_files.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/storage/secure_token_store.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initLocale();
  await sweepSensitiveFiles();
  final prefs = await SharedPreferences.getInstance();
  final tokens = SecureTokenStore();
  await tokens.wipeIfFreshInstall(prefs);
  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
      ],
      child: const PramuApp(),
    ),
  );
}
