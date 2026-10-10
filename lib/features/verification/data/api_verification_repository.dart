import 'package:dio/dio.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/features/verification/domain/verification_repository.dart';

class ApiVerificationRepository implements VerificationRepository {
  ApiVerificationRepository(this._api);
  final ApiClient _api;

  ProgressCallback? _p(Progress? f) =>
      f == null ? null : (sent, total) => f(total > 0 ? sent / total : 0);

  @override
  Future<Verification> current() async =>
      Verification.fromJson(await _api.get('/verification') as Json);

  @override
  Future<Verification> submit({
    required String ktpPath,
    required String selfiePath,
    required String nik,
    Progress? onProgress,
  }) async {
    final form = FormData.fromMap({
      'nik': nik,
      'ktp': await MultipartFile.fromFile(ktpPath, filename: 'ktp.jpg'),
      'selfie': await MultipartFile.fromFile(
        selfiePath,
        filename: 'selfie.jpg',
      ),
    });
    return Verification.fromJson(
      await _api.post(
        '/verification',
        data: form,
        options: ApiClient.upload,
        onProgress: _p(onProgress),
      ) as Json,
    );
  }

  @override
  Future<Verification> skck() async =>
      Verification.fromJson(await _api.get('/me/skck') as Json);

  @override
  Future<Verification> uploadSkck(String path, {Progress? onProgress}) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(path)});
    return Verification.fromJson(
      await _api.post(
        '/me/skck',
        data: form,
        options: ApiClient.upload,
        onProgress: _p(onProgress),
      ) as Json,
    );
  }
}
