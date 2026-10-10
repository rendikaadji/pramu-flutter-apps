import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/app.dart';
import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/router/app_router.dart';
import 'package:pramu_apps/features/verification/data/photo_service.dart';
import 'package:pramu_apps/features/verification/presentation/state/verification_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memory_token_store.dart';

/// PNG 1x1 valid untuk pratinjau Image.memory di test.
final tinyPng = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

/// Pengganti image_picker: mencatat file yang dibuat/dihapus tanpa menyentuh disk.
class FakePhotoService implements PhotoService {
  final created = <String>[];
  final deleted = <String>[];
  PhotoException? failWith;
  int calls = 0;
  PhotoSource? lastSource;
  bool? lastFront;

  @override
  Future<CapturedPhoto?> capture(
    PhotoSource source, {
    bool front = false,
  }) async {
    calls++;
    lastSource = source;
    lastFront = front;
    if (failWith != null) throw failWith!;
    final path = '/fake/${created.length}.jpg';
    created.add(path);
    return CapturedPhoto(path, tinyPng);
  }

  @override
  Future<void> delete(CapturedPhoto? photo) async {
    if (photo != null) deleted.add(photo.path);
  }
}

class AppEnv {
  AppEnv(this.container, this.backend, this.photos);
  final ProviderContainer container;
  final MockBackend backend;
  final FakePhotoService photos;

  void go(String path) => container.read(routerProvider).go(path);
}

/// Aplikasi penuh + mock backend tanpa latensi, layar 360x800, skala teks [textScale].
Future<AppEnv> bootApp(
  WidgetTester tester, {
  String? user,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearAllTestValues();
  });
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tokens = MemoryTokenStore();
  final backend = MockBackend(tokens: tokens, latency: Duration.zero);
  if (user != null) {
    await tokens.write(MockBackend.tokenFor(backend.userByName(user).id));
  }
  final photos = FakePhotoService();
  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      tokenStoreProvider.overrideWithValue(tokens),
      mockBackendProvider.overrideWithValue(backend),
      photoServiceProvider.overrideWithValue(photos),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PramuApp()),
  );
  await tester.pumpAndSettle();
  return AppEnv(container, backend, photos);
}

/// Menggulir hingga widget berkunci [key] terbangun dan terlihat (daftar malas).
Future<void> reveal(WidgetTester tester, Key key) async {
  final f = find.byKey(key);
  if (f.evaluate().isEmpty) {
    final list = find.byType(Scrollable).first;
    // dari atas ke bawah, kecuali sudah ketemu
    await tester.fling(list, const Offset(0, 3000), 3000);
    await tester.pumpAndSettle();
    if (f.evaluate().isEmpty) {
      await tester.scrollUntilVisible(f, 200, scrollable: list, maxScrolls: 60);
    }
  }
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
}

/// Ketik ke field `AppTextField` berkunci [key] (TextField di dalamnya).
Future<void> typeInto(WidgetTester tester, Key key, String text) async {
  await reveal(tester, key);
  final field = find.descendant(
    of: find.byKey(key),
    matching: find.byType(TextField),
  );
  await tester.enterText(field, text);
}

/// Ketik OTP lewat field tersembunyi di dalam [key].
Future<void> typeOtp(WidgetTester tester, Key key, String code) =>
    typeInto(tester, key, code);

Future<void> tapKey(WidgetTester tester, Key key) async {
  await reveal(tester, key);
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}
