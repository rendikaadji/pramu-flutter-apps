import 'package:dio/dio.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/auth/domain/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);
  final ApiClient _api;

  AuthSession _session(Object? d) {
    final j = d as Json;
    return AuthSession(
      j['token'] as String,
      AuthUser.fromJson(j['user'] as Json),
    );
  }

  @override
  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) => _api.post(
    '/auth/register',
    data: {'name': name, 'phone': phone, 'email': email, 'password': password},
  );

  @override
  Future<void> sendOtp(String phone) =>
      _api.post('/auth/otp/send', data: {'phone': phone});

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
  }) async => _session(
    await _api.post('/auth/otp/verify', data: {'phone': phone, 'code': code}),
  );

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async => _session(
    await _api.post(
      '/auth/login',
      data: {'identifier': identifier, 'password': password},
    ),
  );

  @override
  Future<void> logout() => _api.post('/auth/logout');

  @override
  Future<AuthUser> me() async =>
      AuthUser.fromJson(await _api.get('/me') as Json);

  @override
  Future<AuthUser> setRoles(Set<Role> roles) async => AuthUser.fromJson(
    await _api.put(
      '/me/roles',
      data: {
        'roles': [for (final r in roles) r.name],
      },
    ) as Json,
  );

  @override
  Future<AuthUser> switchRole(Role role) async => AuthUser.fromJson(
    await _api.post('/me/switch-role', data: {'role': role.name}) as Json,
  );

  @override
  Future<AuthUser> uploadPhoto(String path) async => AuthUser.fromJson(
    await _api.post(
      '/me/photo',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: 'photo.jpg'),
      }),
      options: ApiClient.upload,
    ) as Json,
  );

  @override
  Future<AuthUser> removePhoto() async {
    await _api.delete('/me/photo');
    return me();
  }

  @override
  Future<void> requestPasswordReset(String identifier) =>
      _api.post('/auth/password/forgot', data: {'identifier': identifier});

  @override
  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) => _api.post(
    '/auth/password/reset',
    data: {'identifier': identifier, 'code': code, 'password': newPassword},
  );

  @override
  Future<List<Device>> devices() async => [
    for (final d in await _api.get('/me/devices') as List)
      Device.fromJson(d as Json),
  ];

  @override
  Future<void> revokeDevice(String id) => _api.delete('/me/devices/$id');
}
