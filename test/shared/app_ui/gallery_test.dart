import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/shared/app_ui/gallery/design_gallery_screen.dart';

void main() {
  // Smoke: tanpa overflow/exception pada ponsel 360dp, dua tema. Font test (Ahem) ~1,8x
  // lebih lebar dari Plex, jadi skala 1,3 di sini kira-kira setara 200% pada font asli.
  for (final dark in [false, true]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('galeri render dark=$dark skala=$scale', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(home: DesignGalleryScreen(initialDark: dark)),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
