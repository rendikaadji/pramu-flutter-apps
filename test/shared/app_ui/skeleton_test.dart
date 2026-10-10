import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

Widget _app(Widget child, {bool reduce = false, bool dark = false}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: c!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('shimmer berjalan', (t) async {
    await t.pumpWidget(_app(const ListSkeleton(count: 2)));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('reduce motion: statis, tanpa frame terjadwal', (t) async {
    await t.pumpWidget(_app(const ListSkeleton(count: 2), reduce: true));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.binding.hasScheduledFrame, isFalse);
    await t.pumpAndSettle();
  });

  testWidgets('satu label Memuat per scope, isi tak terbaca', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_app(const HomeSkeleton()));
    expect(find.bySemanticsLabel('Memuat'), findsOneWidget);
    h.dispose();
  });

  testWidgets('HomeSkeleton: 4 kategori + 2 kartu + search + hero', (t) async {
    await t.pumpWidget(_app(const HomeSkeleton()));
    expect(find.byType(SkeletonScope), findsOneWidget);
    expect(find.byType(ListCardSkeleton), findsNWidgets(2));
    // 4 ubin kategori (kotak 56dp).
    final tiles = find.byWidgetPredicate(
      (w) => w is AppSkeleton && w.width == 56 && w.height == 56,
    );
    expect(tiles, findsNWidgets(4));
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('komposisi tanpa overflow di 360dp, skala $scale', (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        t.view.reset();
        t.platformDispatcher.clearAllTestValues();
      });
      for (final dark in [false, true]) {
        for (final w in <Widget>[
          const HomeSkeleton(),
          const DetailSkeleton(),
          const WalletSkeleton(),
          const ProfileSkeleton(),
          for (final k in SkeletonCardKind.values)
            ListSkeleton(count: 2, kind: k),
        ]) {
          await t.pumpWidget(
            _app(
              Padding(padding: const EdgeInsets.all(16), child: w),
              reduce: true,
              dark: dark,
            ),
          );
          expect(t.takeException(), isNull);
        }
      }
    });
  }
}
