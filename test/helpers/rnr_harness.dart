import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/theme/app_theme.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memory_token_store.dart';

/// Harness untuk layar rating / notifikasi / laporan: MockBackend tanpa latensi, login sebagai [user].
class Rig {
  Rig._(this.backend, this.tokens, this.prefs);

  final MockBackend backend;
  final MemoryTokenStore tokens;
  final SharedPreferences prefs;

  static Future<Rig> login(String user) async {
    SharedPreferences.setMockInitialValues({});
    await initLocale();
    final tokens = MemoryTokenStore();
    final b = MockBackend(tokens: tokens, latency: Duration.zero);
    tokens.write(MockBackend.tokenFor(b.userByName(user).id));
    return Rig._(b, tokens, await SharedPreferences.getInstance());
  }

  String get meId => backend.currentUserId!;

  Widget app({
    Widget? home,
    GoRouter? router,
    List<Override> overrides = const [],
    double textScale = 1,
  }) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      tokenStoreProvider.overrideWithValue(tokens),
      mockBackendProvider.overrideWithValue(backend),
      ...overrides,
    ],
    child: Builder(
      builder: (context) {
        Widget scale(BuildContext c, Widget? child) => MediaQuery(
          data: MediaQuery.of(c)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
        return router != null
            ? MaterialApp.router(
                theme: AppTheme.light(),
                routerConfig: router,
                builder: scale,
              )
            : MaterialApp(theme: AppTheme.light(), home: home, builder: scale);
      },
    ),
  );
}
