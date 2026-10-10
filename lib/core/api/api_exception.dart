/// Kontrak error envelope (Spec §2): `{"error":{"code","message","fields"}}`.
class ApiException implements Exception {
  ApiException({
    required this.status,
    required this.code,
    required this.message,
    this.fields = const {},
    this.retryAfter,
  });

  final int status; // 0 = jaringan; 401/403/404/409/422/429/5xx
  final String code; // mis. BOOKING_INVALID_STATE
  final String message; // Indonesia, aman ditampilkan
  final Map<String, List<String>> fields; // 422
  final Duration? retryAfter; // header Retry-After (detik) pada 429

  factory ApiException.fromBody(
    int status,
    Object? body, {
    Duration? retryAfter,
  }) {
    final e = (body is Map ? body['error'] : null) as Map?;
    return ApiException(
      retryAfter: retryAfter,
      status: status,
      code: (e?['code'] as String?) ?? 'UNKNOWN',
      message: (e?['message'] as String?) ?? 'Terjadi kesalahan. Coba lagi.',
      fields: {
        for (final en in (e?['fields'] as Map? ?? {}).entries)
          en.key as String: List<String>.from(en.value as List),
      },
    );
  }

  static const network = 0;

  bool get isNetwork => status == network;
  bool get isUnauthorized => status == 401;
  bool get isConflict => status == 409;
  bool get isValidation => status == 422;
  bool get isRateLimited => status == 429;

  @override
  String toString() => 'ApiException($status $code)';
}
