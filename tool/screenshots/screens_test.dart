// ignore_for_file: invalid_use_of_visible_for_testing_member
// Harness screenshot layar kunci. Bukan bagian `flutter test` biasa (ada di tool/).
//
//   flutter test tool/screenshots/screens_test.dart --update-goldens
//   SHOTS=home flutter test tool/screenshots/screens_test.dart --update-goldens   (filter nama)
//
// Hasil: tool/screenshots/out/<layar>__<varian>.png  (varian: light, dark, light-x13)
// Font: Segoe UI (UI), Georgia (display), Consolas (mono) dari C:\Windows\Fonts agar teks bukan kotak
// Ahem. Ini perkiraan; font nyata (Plex/Fraunces) berbeda tipis.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/app.dart';
import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/router/app_router.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/theme/app_theme.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/verification/presentation/state/verification_state.dart';
import 'package:pramu_apps/shared/app_ui/gallery/design_gallery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/helpers/core_boot.dart' show FakePhotoService;
import '../../test/helpers/memory_token_store.dart';

const _fonts = 'C:/Windows/Fonts';

Future<void> _loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    final bytes = File('$_fonts/$f').readAsBytesSync();
    l.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await l.load();
}

Future<void> _settle(WidgetTester t) async {
  try {
    await t.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 4),
    );
  } catch (_) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

class _Env {
  _Env(this.c, this.b);
  final ProviderContainer c;
  final MockBackend b;
  void go(String p) => c.read(routerProvider).go(p);
}

typedef _Go = Future<void> Function(WidgetTester, _Env);

final _filter = Platform.environment['SHOTS'];

void main() {
  setUpAll(() async {
    await initLocale();
    // Nama keluarga = yang dirujuk AppFonts, sehingga teks tampil dengan metrik nyata.
    await _loadFont('IBMPlexSans', ['segoeui.ttf', 'segoeuib.ttf']);
    await _loadFont('Fraunces', ['georgia.ttf', 'georgiab.ttf']);
    await _loadFont('IBMPlexMono', ['consola.ttf', 'consolab.ttf']);
    await _loadFont('Roboto', ['segoeui.ttf', 'segoeuib.ttf']);
    await _loadLucide();
    await _loadMaterialIcons();
  });

  Future<_Env> boot(
    WidgetTester t, {
    String? user,
    required bool dark,
    required double scale,
  }) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = scale;
    t.platformDispatcher.platformBrightnessTestValue = dark
        ? Brightness.dark
        : Brightness.light;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
      t.platformDispatcher.clearAllTestValues();
    });
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokens = MemoryTokenStore();
    final backend = MockBackend(tokens: tokens, latency: Duration.zero);
    if (user != null) {
      await tokens.write(MockBackend.tokenFor(backend.userByName(user).id));
    }
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
        mockBackendProvider.overrideWithValue(backend),
        photoServiceProvider.overrideWithValue(FakePhotoService()),
      ],
    );
    addTearDown(container.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(container: container, child: const PramuApp()),
    );
    await _settle(t);
    return _Env(container, backend);
  }

  Future<void> tapKey(WidgetTester t, Key k) async {
    final f = find.byKey(k);
    await t.ensureVisible(f);
    await t.pump();
    await t.tap(f);
    await _settle(t);
  }

  Future<void> type(WidgetTester t, Key k, String s) async {
    final f = find.descendant(
      of: find.byKey(k),
      matching: find.byType(TextField),
    );
    await t.ensureVisible(f);
    await t.enterText(f, s);
    await t.pump();
  }

  final screens = <String, (String?, _Go)>{};
  void screen(String name, String? user, _Go go) => screens[name] = (user, go);

  Booking sitiBooking(MockBackend b) => b.bookings.values.firstWhere(
    (x) => x.assistant.name == 'Siti' && x.seeker.name == 'Bu Rina',
  );

  screen('01-welcome', null, (t, e) async {});
  screen('02-register', null, (t, e) async {
    await tapKey(t, K.welcomeRegister);
  });
  screen('03-otp', null, (t, e) async {
    await tapKey(t, K.welcomeRegister);
    await type(t, K.registerName, 'Budi Santoso');
    await type(t, K.registerPhone, '081200001111');
    await type(t, K.registerEmail, 'budi@example.com');
    await type(t, K.registerPassword, 'Rahasia123');
    await tapKey(t, K.registerConsent);
    await tapKey(t, K.registerSubmit);
  });
  screen('04-login', null, (t, e) async {
    await tapKey(t, K.welcomeLogin);
  });
  screen('05-home-seeker', 'Bu Rina', (t, e) async {});
  screen('06-home-assistant', 'Siti', (t, e) async {});
  screen('07-search', 'Bu Rina', (t, e) async {
    e.go('/s/search');
  });
  screen('08-listing-detail', 'Siti', (t, e) async {
    final l = e.b.listings.values.firstWhere(
      (x) => x.title == 'Juru masak untuk 4 orang',
    );
    e.go('/listings/${l.id}');
  });
  screen('09-listing-manage', 'Bu Rina', (t, e) async {
    final l = e.b.listings.values.firstWhere(
      (x) => x.title == 'Pengasuh anak usia 3 tahun',
    );
    e.go('/listings/${l.id}/manage');
  });
  screen('10-applicant', 'Bu Rina', (t, e) async {
    final a = e.b.applications.values.firstWhere(
      (x) => x.assistant.name == 'Yuni',
    );
    e.go('/applications/${a.id}/applicant');
  });
  screen('11-chat-list', 'Bu Rina', (t, e) async {
    e.go('/s/chat');
  });
  screen('12-chat-room', 'Bu Rina', (t, e) async {
    final u = e.b.userByName('Bu Rina').id;
    final c = e.b.conversations.values.firstWhere((x) => x.seekerId == u);
    e.go('/chat/${c.id}');
  });
  screen('13-booking', 'Bu Rina', (t, e) async {
    e.go('/bookings/${sitiBooking(e.b).id}');
  });
  screen('14-period-pay', 'Bu Rina', (t, e) async {
    final id = e.b.bookingPeriods[sitiBooking(e.b).id]!.firstWhere(
      (p) => e.b.periods[p]!.status == PeriodStatus.awaitingPayment,
    );
    e.go('/periods/$id/pay');
  });
  screen('15-wallet', 'Siti', (t, e) async {
    e.go('/a/wallet');
  });
  screen('16-account', 'Bu Rina', (t, e) async {
    e.go('/account');
  });
  screen('17-notifications', 'Bu Rina', (t, e) async {
    e.go('/notifications');
  });
  screen('18-verification', 'Dewi', (t, e) async {});

  const variants = <(String, bool, double)>[
    ('light', false, 1.0),
    ('dark', true, 1.0),
    ('light-x13', false, 1.3),
  ];

  for (final entry in screens.entries) {
    if (_filter != null && !entry.key.contains(_filter!)) continue;
    for (final (vn, dark, scale) in variants) {
      testWidgets('${entry.key} $vn', (t) async {
        final e = await boot(t, user: entry.value.$1, dark: dark, scale: scale);
        await entry.value.$2(t, e);
        await _settle(t);
        await expectLater(
          find.byType(PramuApp),
          matchesGoldenFile('out/${entry.key}__$vn.png'),
        );
      });
    }
  }

  for (final (vn, dark, scale) in variants) {
    if (_filter != null && !'99-gallery'.contains(_filter!)) continue;
    testWidgets('99-gallery $vn', (t) async {
      t.view.physicalSize = const Size(390, 2400);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        t.view.reset();
        t.platformDispatcher.clearAllTestValues();
      });
      await t.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: DesignGalleryScreen(initialDark: dark),
        ),
      );
      await t.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('out/99-gallery__$vn.png'),
      );
    });
  }
}

/// flutter test tidak memuat font ikon paket; muat Lucide dari pub cache (lokasi dibaca dari package_config).
Future<void> _loadLucide() async {
  final cfg = File('.dart_tool/package_config.json').readAsStringSync();
  final m = RegExp(
    r'"name":\s*"lucide_icons_flutter",\s*"rootUri":\s*"([^"]+)"',
  ).firstMatch(cfg)!;
  final root = Uri.parse(m.group(1)!).toFilePath();
  final bytes = File('$root/assets/lucide.ttf').readAsBytesSync();
  final l = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await l.load();
}

Future<void> _loadMaterialIcons() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
  final f = File(
    '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (!f.existsSync()) return;
  final l = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  await l.load();
}
