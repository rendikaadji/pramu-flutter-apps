import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

import 'harness.dart';

Color _bg(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(StatusChip),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  const t = AppTokens.light;

  testWidgets('tone menentukan warna container; selalu ada ikon + teks', (
    tester,
  ) async {
    final cases = {
      StatusTone.success: t.successContainer,
      StatusTone.warning: t.warningContainer,
      StatusTone.danger: t.dangerContainer,
      StatusTone.info: t.primaryContainer,
      StatusTone.accent: t.accentContainer,
      StatusTone.neutral: t.sunken,
    };
    for (final e in cases.entries) {
      await tester.pumpWidget(host(StatusChip(label: 'Status', tone: e.key)));
      expect(_bg(tester), e.value, reason: '${e.key}');
      expect(find.text('Status'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    }
  });

  testWidgets('StatusChip.of memetakan kode backend per peran', (tester) async {
    await tester.pumpWidget(
      host(StatusChip.of(StatusDomain.period, 'scheduled')),
    );
    expect(find.text('Terjadwal'), findsOneWidget);
    await tester.pumpWidget(
      host(StatusChip.of(StatusDomain.interview, 'no_show')),
    );
    expect(find.text('Tidak hadir'), findsOneWidget);
    expect(_bg(tester), t.dangerContainer);
  });
}
