import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';

enum Role {
  seeker,
  assistant;

  static Role? from(String? s) {
    for (final r in values) {
      if (r.name == s) return r;
    }
    return null;
  }

  String get label => this == seeker ? 'Pencari' : 'Pelamar';
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.roles = const {},
    this.activeRole,
    this.verification = VerificationStatus.none,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: j['id'] as String,
    name: j['name'] as String,
    phone: j['phone'] as String,
    email: j['email'] as String,
    roles: {
      for (final r in j['roles'] as List? ?? const [])
        if (Role.from(r as String) != null) Role.from(r)!,
    },
    activeRole: Role.from(j['active_role'] as String?),
    verification: VerificationStatus.from(j['verification_status'] as String?),
  );

  final String id;
  final String name;
  final String phone;
  final String email;
  final Set<Role> roles;
  final Role? activeRole;
  final VerificationStatus verification;

  AuthUser copyWith({
    Set<Role>? roles,
    Role? activeRole,
    VerificationStatus? verification,
  }) => AuthUser(
    id: id,
    name: name,
    phone: phone,
    email: email,
    roles: roles ?? this.roles,
    activeRole: activeRole ?? this.activeRole,
    verification: verification ?? this.verification,
  );
}

class AuthSession {
  const AuthSession(this.token, this.user);
  final String token;
  final AuthUser user;
}

class Device {
  const Device({
    required this.id,
    required this.name,
    required this.lastActiveAt,
    this.current = false,
  });

  factory Device.fromJson(Map<String, dynamic> j) => Device(
    id: j['id'] as String,
    name: j['name'] as String,
    lastActiveAt: parseApiTime(j['last_active_at'] as String),
    current: j['current'] as bool? ?? false,
  );

  final String id;
  final String name;
  final DateTime lastActiveAt;
  final bool current;
}
