import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

import 'harness.dart';

void main() {
  testWidgets('tap memanggil onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(AppButton(label: 'Simpan', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Simpan'));
    expect(taps, 1);
  });

  testWidgets('loading menonaktifkan ketukan dan menampilkan spinner', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(AppButton(label: 'Bayar', loading: true, onPressed: () => taps++)),
    );
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('tinggi tombol >= 48dp dan lolos guideline tap target', (
    tester,
  ) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(host(AppButton(label: 'Masuk', onPressed: () {})));
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
  });

  testWidgets('AppIconButton punya label semantik', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      host(AppIconButton(icon: Icons.add, label: 'Tambah', onPressed: () {})),
    );
    expect(find.bySemanticsLabel('Tambah'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
  });
}
