import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/notification/data/noop_push_service.dart';
import 'package:pramu_apps/features/notification/data/notification_providers.dart';
import 'package:pramu_apps/features/notification/domain/push_service.dart';

/// Ganti dengan implementasi FCM saat firebase_messaging dipasang.
final pushServiceProvider = Provider<PushService>(
  (ref) => const NoopPushService(),
);

/// Menjaga token push terdaftar di `/me/devices` selama login. State = token terdaftar.
/// Tonton dari root app (mis. beranda). Logout: `await ref.read(pushTokenSyncProvider.notifier).unregister()`
/// SEBELUM `sessionProvider.notifier.logout()` (setelah logout token API sudah hilang).
class PushTokenSync extends Notifier<String?> {
  bool _hadUser = false;

  @override
  String? build() {
    final uid = ref.watch(sessionProvider.select((s) => s.user?.id));
    if (uid == null) {
      // sesi berakhir (logout/401/revoke): lepas token push perangkat, best effort
      if (_hadUser) {
        _hadUser = false;
        unawaited(
          ref.read(pushServiceProvider).deleteToken().catchError((_) {}),
        );
      }
      return null;
    }
    _hadUser = true;
    final sub = ref.read(pushServiceProvider).onTokenRefresh.listen(_register);
    ref.onDispose(sub.cancel);
    Future.microtask(sync);
    return null;
  }

  /// Daftarkan token bila izin sudah diberikan (panggil juga setelah izin baru diberikan).
  Future<void> sync() async {
    final push = ref.read(pushServiceProvider);
    if (!push.available || await push.permission() != PushPermission.granted) {
      return;
    }
    final t = await push.token();
    if (t != null) await _register(t);
  }

  Future<void> _register(String token) async {
    try {
      await ref.read(notificationRepositoryProvider).registerPushToken(token);
      if (ref.mounted) state = token;
    } on ApiException {
      // dicoba lagi pada sinkronisasi berikutnya
    }
  }

  Future<void> unregister() async {
    final push = ref.read(pushServiceProvider);
    final t = state ?? await push.token();
    if (t != null) {
      try {
        await ref.read(notificationRepositoryProvider).unregisterPushToken(t);
      } on ApiException {
        // logout tetap lanjut
      }
    }
    await push.deleteToken();
    if (ref.mounted) state = null;
  }
}

final pushTokenSyncProvider = NotifierProvider<PushTokenSync, String?>(
  PushTokenSync.new,
);
