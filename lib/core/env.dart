/// Konfigurasi build lewat `--dart-define`. Satu-satunya tempat URL/flag env.
abstract final class Env {
  /// Mock aktif otomatis hanya di build debug/profile; build rilis default API nyata.
  static const useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: !bool.fromEnvironment('dart.vm.product'),
  );
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.pramu.example/api/v1',
  );
  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// Hash SPKI (base64, dipisah koma) untuk certificate pinning. Kosong = nonaktif.
  static const pinnedSpki = String.fromEnvironment('PINNED_SPKI');
  static bool get pinningEnabled => pinnedSpki.isNotEmpty;
}
