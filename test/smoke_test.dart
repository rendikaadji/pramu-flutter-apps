import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/app.dart';
import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/memory_token_store.dart';

Future<ProviderContainer> boot(WidgetTester tester, {String? userName}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tokens = MemoryTokenStore();
  final backend = MockBackend(tokens: tokens, latency: Duration.zero);
  if (userName != null) {
    await tokens.write(MockBackend.tokenFor(backend.userByName(userName).id));
  }
  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      tokenStoreProvider.overrideWithValue(tokens),
      mockBackendProvider.overrideWithValue(backend),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PramuApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(initLocale);

  testWidgets('app boot tanpa sesi -> layar Welcome (M-01)', (tester) async {
    await boot(tester);
    expect(find.byKey(K.welcomeRegister), findsOneWidget);
  });

  testWidgets(
    'sesi tersimpan Pencari verified -> Beranda Pencari dengan 5 tab',
    (tester) async {
      await boot(tester, userName: 'Bu Rina');
      expect(find.byKey(K.notificationBell), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      await tester.tap(find.byKey(K.tab('search')));
      await tester.pumpAndSettle();
      expect(find.text('Cari asisten'), findsWidgets);
      await tester.tap(find.byKey(K.tab('profile')));
      await tester.pumpAndSettle();
      expect(find.text('Peran aktif'), findsOneWidget);
    },
  );

  testWidgets('Asisten verified -> 5 tab', (tester) async {
    await boot(tester, userName: 'Siti');
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('akun belum verifikasi -> gerbang verifikasi (M-10)', (
    tester,
  ) async {
    await boot(tester, userName: 'Dewi');
    expect(find.byKey(K.verificationStart), findsOneWidget);
  });

  testWidgets('logout membersihkan token dan kembali ke Welcome', (
    tester,
  ) async {
    final c = await boot(tester, userName: 'Bu Rina');
    await c.read(sessionProvider.notifier).logout();
    await tester.pumpAndSettle();
    expect(find.byKey(K.welcomeRegister), findsOneWidget);
    expect(await c.read(tokenStoreProvider).read(), isNull);
  });
}
