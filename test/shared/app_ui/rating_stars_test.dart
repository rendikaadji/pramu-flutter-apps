import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

import 'harness.dart';

void main() {
  testWidgets('tampil: label semantik berisi nilai dan jumlah ulasan', (
    tester,
  ) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(host(const RatingStars(value: 4.5, count: 12)));
    expect(
      find.bySemanticsLabel('Rating 4,5 dari 5, 12 ulasan'),
      findsOneWidget,
    );
    expect(find.text('4,5 (12 ulasan)'), findsOneWidget); // angka terlihat
    h.dispose();
  });

  testWidgets('input: 5 target >= 48dp, berlabel, memanggil onChanged', (
    tester,
  ) async {
    final h = tester.ensureSemantics();
    int? v;
    await tester.pumpWidget(
      host(RatingStars(value: 2, onChanged: (x) => v = x)),
    );
    for (var i = 1; i <= 5; i++) {
      expect(find.bySemanticsLabel('Beri $i bintang'), findsOneWidget);
    }
    await tester.tap(find.bySemanticsLabel('Beri 4 bintang'));
    expect(v, 4);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    h.dispose();
  });
}
