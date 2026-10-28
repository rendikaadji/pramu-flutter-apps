import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/router/app_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';

void main() {
  final patterns = allowedPatterns(allFeatureRoutes);
  const ulid = '01ARZ3NDEKTSV4RRFFQ69G5FAV';
  String? taken;
  String? redirect(SessionState s, String location) => appRedirect(
    s,
    Uri.parse(location),
    () {
      final t = taken;
      taken = null;
      return t;
    },
    (v) => taken = v,
    patterns,
  );

  SessionState authed(
    Role? role, {
    VerificationStatus v = VerificationStatus.verified,
    bool gateSeen = false,
  }) => SessionState(
    status: SessionStatus.authenticated,
    user: AuthUser(
      id: ulid,
      name: 'Uji',
      phone: '+6281200000000',
      email: 'uji@example.com',
      roles: role == null ? {} : {role},
      activeRole: role,
      verification: v,
    ),
    verificationGateSeen: gateSeen,
  );

  const guest = SessionState(status: SessionStatus.unauthenticated);

  setUp(() => taken = null);

  test('booting -> splash dan mengingat deep link valid', () {
    expect(redirect(const SessionState(), '/bookings/$ulid'), '/splash');
    expect(taken, '/bookings/$ulid');
  });

  test('tamu: rute publik lolos, lainnya ke welcome dan tujuan diingat', () {
    expect(redirect(guest, Routes.login), isNull);
    expect(redirect(guest, '/bookings/$ulid'), Routes.welcome);
    expect(taken, '/bookings/$ulid');
    taken = null;
    expect(redirect(guest, '/bookings/bukan-ulid'), Routes.welcome);
    expect(taken, isNull);
  });

  test(
    'login sukses: lanjut ke tujuan tersimpan, jika tidak ke beranda peran',
    () {
      taken = '/bookings/$ulid';
      expect(redirect(authed(Role.seeker), Routes.login), '/bookings/$ulid');
      expect(redirect(authed(Role.seeker), '/'), Routes.seekerHome);
      expect(
        redirect(authed(Role.assistant), Routes.welcome),
        Routes.assistantHome,
      );
    },
  );

  test('belum punya peran -> pilih peran', () {
    expect(redirect(authed(null), Routes.seekerHome), Routes.pickRole);
    expect(redirect(authed(null), Routes.pickRole), isNull);
  });

  test('guard peran: /a/* untuk pencari dan /s/* untuk asisten dialihkan', () {
    expect(
      redirect(authed(Role.seeker), Routes.assistantJobs),
      Routes.seekerHome,
    );
    expect(
      redirect(authed(Role.assistant), Routes.seekerJobs),
      Routes.assistantHome,
    );
    expect(redirect(authed(Role.seeker), Routes.seekerJobs), isNull);
  });

  test(
    'allowlist deep link: path tak dikenal dan ULID tidak valid ke beranda',
    () {
      final s = authed(Role.seeker);
      expect(redirect(s, '/admin/panel'), Routes.seekerHome);
      expect(redirect(s, '/bookings/123'), Routes.seekerHome);
      expect(redirect(s, '/bookings/$ulid/../x'), Routes.seekerHome);
      expect(redirect(s, '/bookings/$ulid'), isNull);
      expect(redirect(s, '/pay/return?listing=$ulid'), isNull);
      expect(redirect(s, '/pay/return?listing=jahat'), Routes.seekerHome);
      expect(redirect(s, '/listings/new?draft=$ulid'), isNull);
    },
  );

  test('gerbang verifikasi sekali untuk akun belum verifikasi di tab root', () {
    expect(
      redirect(
        authed(Role.seeker, v: VerificationStatus.none),
        Routes.seekerHome,
      ),
      Routes.verificationGate,
    );
    expect(
      redirect(
        authed(Role.seeker, v: VerificationStatus.none, gateSeen: true),
        Routes.seekerHome,
      ),
      isNull,
    );
    expect(
      redirect(
        authed(Role.seeker, v: VerificationStatus.pending),
        Routes.seekerHome,
      ),
      isNull,
    );
    expect(
      redirect(
        authed(Role.seeker, v: VerificationStatus.none),
        Routes.verificationStatus,
      ),
      isNull,
    );
  });

  test('semua path rute fitur unik', () {
    final all = patterns.map((e) => e.pattern).toList();
    expect(all.toSet().length, all.length);
  });
}
