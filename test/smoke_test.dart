import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/app.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/memory_token_store.dart';

void main() {
  setUpAll(initLocale);

  testWidgets('aplikasi menyala dan menampilkan layar sementara', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
        ],
        child: const PramuApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aplikasi sedang dibangun ulang.'), findsOneWidget);
  });
}
