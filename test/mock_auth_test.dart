import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/features/auth/data/mock_auth_repository.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';

import 'helpers/memory_token_store.dart';

void main() {
  late MockBackend backend;
  late MockAuthRepository auth;
  late MemoryTokenStore tokens;

  setUp(() {
    tokens = MemoryTokenStore();
    backend = MockBackend(tokens: tokens, latency: Duration.zero);
    auth = MockAuthRepository(backend);
  });

  Future<ApiException> failure(Future<Object?> f) async {
    try {
      await f;
    } on ApiException catch (e) {
      return e;
    }
    fail('seharusnya melempar ApiException');
  }

  test('login seed Bu Rina berhasil dan token memetakan ke pengguna', () async {
    final s = await auth.login(
      identifier: '081234567890',
      password: kMockPassword,
    );
    expect(s.user.name, 'Bu Rina');
    expect(s.user.activeRole, Role.seeker);
    await tokens.write(s.token);
    expect((await auth.me()).id, s.user.id);
  });

  test('login salah -> 422 generik; akun suspend -> 403', () async {
    expect(
      (await failure(auth.login(identifier: '081234567890', password: 'salah')))
          .status,
      422,
    );
    expect(
      (await failure(
        auth.login(identifier: '08999999999', password: kMockPassword),
      )).code,
      'ACCOUNT_SUSPENDED',
    );
  });

  test('daftar -> OTP salah 422, OTP benar masuk, pilih peran', () async {
    await auth.register(
      name: 'Dina',
      phone: '081200000001',
      email: 'dina@example.com',
      password: 'sandi1234',
    );
    final bad = await failure(
      auth.verifyOtp(phone: '081200000001', code: '000000'),
    );
    expect((bad.status, bad.code), (422, 'OTP_INVALID'));
    final s = await auth.verifyOtp(phone: '081200000001', code: kMockOtpOk);
    expect(s.user.roles, isEmpty);
    await tokens.write(s.token);
    final u = await auth.setRoles({Role.assistant});
    expect(u.activeRole, Role.assistant);
  });

  test('duplikat HP/email -> 422 dengan fields', () async {
    final e = await failure(
      auth.register(
        name: 'X',
        phone: '081234567890',
        email: 'rina@example.com',
        password: 'sandi1234',
      ),
    );
    expect(e.status, 422);
    expect(e.fields.keys, containsAll(['phone', 'email']));
  });

  test('5 OTP salah -> 429 dan OTP benar pun ditolak', () async {
    await auth.register(
      name: 'Eko',
      phone: '081200000002',
      email: 'eko@example.com',
      password: 'sandi1234',
    );
    for (var i = 0; i < 4; i++) {
      expect(
        (await failure(auth.verifyOtp(phone: '081200000002', code: '000000')))
            .status,
        422,
      );
    }
    expect(
      (await failure(auth.verifyOtp(phone: '081200000002', code: '000000')))
          .status,
      429,
    );
    expect(
      (await failure(auth.verifyOtp(phone: '081200000002', code: kMockOtpOk)))
          .status,
      429,
    );
  });

  test(
    'tanpa token -> 401; ganti peran hanya untuk peran yang dimiliki',
    () async {
      expect((await failure(auth.me())).status, 401);
      final s = await auth.login(
        identifier: '081355500002',
        password: kMockPassword,
      ); // Bu Maya, 2 peran
      await tokens.write(s.token);
      expect(
        (await auth.switchRole(Role.assistant)).activeRole,
        Role.assistant,
      );
      final rina = await auth.login(
        identifier: '081234567890',
        password: kMockPassword,
      );
      await tokens.write(rina.token);
      expect((await failure(auth.switchRole(Role.assistant))).status, 403);
    },
  );
}
