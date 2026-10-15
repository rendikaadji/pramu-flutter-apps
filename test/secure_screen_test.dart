import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/platform/secure_screen.dart';
import 'package:pramu_apps/core/theme/app_theme.dart';

void main() {
  final calls = <bool>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('pramu/platform'), (
          c,
        ) async {
          if (c.method == 'setSecure') {
            calls.add((c.arguments as Map)['on'] as bool);
          }
          return null;
        });
  });

  Widget host({required bool active}) => MaterialApp(
    theme: AppTheme.light(),
    home: TickerMode(
      enabled: active,
      child: const SecureScreenGuard(child: SizedBox()),
    ),
  );

  testWidgets('tab tidak aktif tidak menyalakan FLAG_SECURE', (tester) async {
    await tester.pumpWidget(host(active: false));
    expect(calls, isEmpty);
  });

  testWidgets('flag menyala saat terlihat dan mati saat tab disembunyikan', (
    tester,
  ) async {
    await tester.pumpWidget(host(active: true));
    expect(calls, [true]);
    await tester.pumpWidget(host(active: false));
    expect(calls, [true, false]);
    await tester.pumpWidget(host(active: true));
    expect(calls, [true, false, true]);
  });

  testWidgets('flag mati saat layar dibuang', (tester) async {
    await tester.pumpWidget(host(active: true));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(calls, [true, false]);
  });
}
