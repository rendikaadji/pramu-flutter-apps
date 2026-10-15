import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Token HANYA lewat sini (MOB-SEC-01). `cached` sinkron untuk interceptor.
abstract interface class TokenStore {
  String? get cached;
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _s =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _key = 'auth_token';
  static const _installedFlag = 'installed_v1';
  final FlutterSecureStorage _s;
  String? _cached;

  @override
  String? get cached => _cached;

  @override
  Future<String?> read() async => _cached = await _s.read(key: _key);

  @override
  Future<void> write(String token) async {
    _cached = token;
    await _s.write(key: _key, value: token);
  }

  @override
  Future<void> clear() async {
    _cached = null;
    await _s.delete(key: _key);
  }

  /// Keychain iOS bertahan setelah uninstall: instalasi baru (flag prefs belum ada) -> hapus.
  Future<void> wipeIfFreshInstall(SharedPreferences prefs) async {
    if (prefs.getBool(_installedFlag) ?? false) return;
    await _s.deleteAll();
    await prefs.setBool(_installedFlag, true);
  }
}
