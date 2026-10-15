import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/auth/domain/auth_repository.dart';

/// Kredensial mock: lihat docs/09. OTP benar `123456`, salah `000000` (atau apa pun selain itu);
/// 5 percobaan salah -> 429.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._b);
  final MockBackend _b;

  AuthUser _dto(MockUser u) => AuthUser(
    id: u.id,
    name: u.name,
    phone: u.phone,
    email: u.email,
    roles: {...u.roles},
    activeRole: u.activeRole,
    verification: u.verification,
    photoUrl: u.photoUrl,
  );

  AuthSession _session(MockUser u) =>
      AuthSession(MockBackend.tokenFor(u.id), _dto(u));

  MockUser? _find(String identifier) {
    final key = isValidPhone(identifier)
        ? normalizePhone(identifier)
        : identifier.trim().toLowerCase();
    for (final u in _b.users.values) {
      if (u.phone == key || u.email == key) return u;
    }
    return null;
  }

  @override
  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) => _b.run(() {
    final fields = <String, List<String>>{
      if (name.trim().isEmpty) 'name': ['Nama wajib diisi'],
      if (!isValidPhone(phone)) 'phone': ['Format nomor HP tidak valid'],
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email))
        'email': ['Format email tidak valid'],
      if (password.length < 8) 'password': ['Kata sandi minimal 8 karakter'],
    };
    if (fields.isEmpty) {
      final p = normalizePhone(phone);
      if (_b.users.values.any((u) => u.phone == p)) {
        fields['phone'] = ['Nomor HP sudah terdaftar'];
      }
      if (_b.users.values.any((u) => u.email == email.trim().toLowerCase())) {
        fields['email'] = ['Email sudah terdaftar'];
      }
    }
    if (fields.isNotEmpty) {
      apiFail(422, 'VALIDATION_FAILED', 'Periksa kembali data Anda.', fields);
    }
    final u = MockUser(
      id: _b.newId(),
      name: name.trim(),
      phone: normalizePhone(phone),
      email: email.trim().toLowerCase(),
      password: password,
    )..phoneVerified = false;
    _b.users[u.id] = u;
  });

  @override
  Future<void> sendOtp(String phone) => _b.run(() {});

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
  }) => _b.run(() {
    final p = normalizePhone(phone);
    final u =
        _find(p) ??
        apiFail(422, 'OTP_INVALID', 'Kode OTP salah.', {
          'code': ['Kode OTP salah'],
        });
    const tooMany = 'Terlalu banyak percobaan. Coba lagi dalam 60 menit.';
    if ((_b.otpFails[p] ?? 0) >= 5) {
      apiFail(429, 'OTP_TOO_MANY_ATTEMPTS', tooMany);
    }
    if (code != kMockOtpOk) {
      final n = _b.otpFails[p] = (_b.otpFails[p] ?? 0) + 1;
      if (n >= 5) apiFail(429, 'OTP_TOO_MANY_ATTEMPTS', tooMany);
      apiFail(422, 'OTP_INVALID', 'Kode OTP salah.', {
        'code': ['Kode OTP salah'],
      });
    }
    _b.otpFails.remove(p);
    u.phoneVerified = true;
    return _session(u);
  });

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) => _b.run(() {
    final u = _find(identifier);
    if (u == null || u.password != password) {
      apiFail(
        422,
        'INVALID_CREDENTIALS',
        'Nomor HP/email atau kata sandi salah.',
      );
    }
    if (u.suspended) {
      apiFail(
        403,
        'ACCOUNT_SUSPENDED',
        'Akun Anda ditangguhkan. Hubungi bantuan.',
      );
    }
    if (!u.phoneVerified) {
      apiFail(403, 'PHONE_NOT_VERIFIED', 'Nomor HP belum diverifikasi.');
    }
    return _session(u);
  });

  @override
  Future<void> logout() => _b.run(() {});

  @override
  Future<AuthUser> me() => _b.run(() => _dto(_b.me));

  @override
  Future<AuthUser> setRoles(Set<Role> roles) => _b.run(() {
    if (roles.isEmpty) {
      apiFail(422, 'VALIDATION_FAILED', 'Pilih minimal satu peran.', {
        'roles': ['Pilih minimal satu peran'],
      });
    }
    final u = _b.me;
    u.roles = {...roles};
    if (u.activeRole == null || !roles.contains(u.activeRole)) {
      u.activeRole = roles.first;
    }
    return _dto(u);
  });

  @override
  Future<AuthUser> switchRole(Role role) => _b.run(() {
    final u = _b.me;
    if (!u.roles.contains(role)) {
      apiFail(403, 'ROLE_NOT_OWNED', 'Anda belum memiliki peran ini.');
    }
    u.activeRole = role;
    return _dto(u);
  });

  @override
  Future<AuthUser> uploadPhoto(String path) => _b.run(() {
    final u = _b.me;
    _setPhoto(u, Uri.file(path).toString());
    return _dto(u);
  });

  @override
  Future<AuthUser> removePhoto() => _b.run(() {
    final u = _b.me;
    _setPhoto(u, null);
    return _dto(u);
  });

  /// Server menyinkronkan foto akun ke profil asisten (satu sumber foto).
  void _setPhoto(MockUser u, String? url) {
    u.photoUrl = url;
    final p = _b.profiles[u.id];
    if (p != null) _b.profiles[u.id] = p.withPhoto(url);
  }

  @override
  Future<void> requestPasswordReset(String identifier) => _b.run(() {});

  @override
  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) => _b.run(() {
    final u = _find(identifier);
    if (u == null || code != kMockOtpOk) {
      apiFail(422, 'OTP_INVALID', 'Kode OTP salah.', {
        'code': ['Kode OTP salah'],
      });
    }
    if (newPassword.length < 8) {
      apiFail(422, 'VALIDATION_FAILED', 'Periksa kembali data Anda.', {
        'password': ['Kata sandi minimal 8 karakter'],
      });
    }
    u.password = newPassword;
  });

  @override
  Future<List<Device>> devices() =>
      _b.run(() => List.of(_b.devices[_b.me.id] ?? const []));

  @override
  Future<void> revokeDevice(String id) =>
      _b.run(() => _b.devices[_b.me.id]?.removeWhere((d) => d.id == id));
}
