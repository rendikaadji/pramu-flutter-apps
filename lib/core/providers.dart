import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/storage/secure_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wajib di-override di main()/test dengan instance hasil `SharedPreferences.getInstance()`.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override prefsProvider'),
);

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

/// UUID lokal per instalasi (header X-Device-Id).
final deviceIdProvider = Provider<String>((ref) {
  final prefs = ref.watch(prefsProvider);
  var id = prefs.getString('device_id');
  if (id == null) {
    id = uuidV4();
    prefs.setString('device_id', id);
  }
  return id;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    tokens: ref.watch(tokenStoreProvider),
    deviceId: ref.watch(deviceIdProvider),
    // Token ditolak: sesi dihapus dan router mengarahkan ke layar masuk.
    onUnauthorized: () => ref.read(sessionProvider.notifier).tokenDitolak(),
  ),
);
