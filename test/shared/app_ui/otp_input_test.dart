import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

import 'harness.dart';

Finder _digit(int box, String d) =>
    find.descendant(of: find.byKey(K.otpBox(box)), matching: find.text(d));

String _value(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  testWidgets('digit mengisi kotak berurutan; onCompleted di kotak terakhir', (
    tester,
  ) async {
    String? done;
    await tester.pumpWidget(host(OtpInput(onCompleted: (v) => done = v)));
    await tester.enterText(find.byType(TextField), '12');
    await tester.pump();
    expect(_digit(0, '1'), findsOneWidget);
    expect(_digit(1, '2'), findsOneWidget);
    expect(done, isNull);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(_digit(5, '6'), findsOneWidget);
    expect(done, '123456');
  });

  testWidgets('hanya angka dan maksimal 6 digit', (tester) async {
    await tester.pumpWidget(host(const OtpInput()));
    await tester.enterText(find.byType(TextField), '12a3456789');
    await tester.pump();
    expect(_value(tester), '123456');
  });

  testWidgets('errorText menampilkan pesan dan mengosongkan isian', (
    tester,
  ) async {
    Widget build(String? e) => host(OtpInput(errorText: e));
    await tester.pumpWidget(build(null));
    await tester.enterText(find.byType(TextField), '111111');
    await tester.pumpWidget(build('Kode salah. Sisa percobaan: 3.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Kode salah. Sisa percobaan: 3.'), findsOneWidget);
    expect(_value(tester), isEmpty);
  });
}
