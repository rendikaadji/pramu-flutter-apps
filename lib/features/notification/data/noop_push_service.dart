import 'package:pramu_apps/features/notification/domain/push_service.dart';

/// Pengganti sampai firebase_messaging dipasang (butuh google-services.json, tidak boleh di repo).
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  bool get available => false;

  @override
  Future<PushPermission> permission() async => PushPermission.notDetermined;

  @override
  Future<PushPermission> requestPermission() async =>
      PushPermission.notDetermined;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<void> deleteToken() async {}

  @override
  Future<void> openSettings() async {}
}
