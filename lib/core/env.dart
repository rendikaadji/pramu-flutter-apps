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

  /// Gagal keras bila build rilis salah konfigurasi: mock aktif, atau API_BASE_URL masih placeholder `.example`.
  static void checkRelease({
    required bool release,
    required bool mock,
    required String apiBaseUrl,
  }) {
    if (!release) return;
    if (mock) {
      throw StateError('USE_MOCK tidak boleh aktif di build rilis.');
    }
    if (Uri.parse(apiBaseUrl).host.endsWith('.example')) {
      throw StateError('API_BASE_URL belum diisi untuk build rilis.');
    }
  }

  /// Hash SPKI (base64, dipisah koma) untuk certificate pinning. Kosong = nonaktif.
  static const pinnedSpki = String.fromEnvironment('PINNED_SPKI');
  static bool get pinningEnabled => pinnedSpki.isNotEmpty;
}
