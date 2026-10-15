import 'package:pramu_apps/core/storage/secure_token_store.dart';

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this._token]);
  String? _token;

  @override
  String? get cached => _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
