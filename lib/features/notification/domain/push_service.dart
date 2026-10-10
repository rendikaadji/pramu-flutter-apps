enum PushPermission { notDetermined, granted, denied }

/// Antarmuka push. Implementasi FCM (firebase_messaging) menyusul; sementara [NoopPushService].
abstract interface class PushService {
  /// false = belum ada backend push (tidak ada banner/rationale, tidak ada token).
  bool get available;

  Future<PushPermission> permission();

  /// Memicu prompt OS. Panggil hanya setelah layar penjelas (pre-permission).
  Future<PushPermission> requestPermission();

  Future<String?> token();
  Stream<String> get onTokenRefresh;
  Future<void> deleteToken();
  Future<void> openSettings();
}
