import 'package:pramu_apps/features/auth/domain/auth.dart';

/// Nomor HP selalu bentuk kanonik (`normalizePhone`, +628...).
abstract interface class AuthRepository {
  /// Membuat akun dan mengirim OTP. 422 `fields` untuk duplikat HP/email.
  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  });

  /// Kirim ulang OTP.
  Future<void> sendOtp(String phone);

  /// 422 OTP salah; 429 setelah 5 percobaan.
  Future<AuthSession> verifyOtp({required String phone, required String code});

  /// [identifier] = HP atau email. 422 kredensial salah (pesan generik); 403 akun disuspend.
  Future<AuthSession> login({
    required String identifier,
    required String password,
  });

  Future<void> logout();
  Future<AuthUser> me();
  Future<AuthUser> setRoles(Set<Role> roles);
  Future<AuthUser> switchRole(Role role);

  /// Foto profil (kedua peran), JPEG terkompres. 422 bila berkas ditolak.
  Future<AuthUser> uploadPhoto(String path);
  Future<AuthUser> removePhoto();

  Future<void> requestPasswordReset(String identifier);
  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  });

  Future<List<Device>> devices();
  Future<void> revokeDevice(String id);
}
