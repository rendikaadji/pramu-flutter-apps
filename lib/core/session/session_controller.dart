import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/platform/sensitive_files.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/auth/data/auth_providers.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';

enum SessionStatus { booting, unauthenticated, authenticated }

class SessionState {
  const SessionState({
    this.status = SessionStatus.booting,
    this.user,
    this.expired = false,
    this.verificationGateSeen = false,
  });

  final SessionStatus status;
  final AuthUser? user;

  /// true bila keluar karena 401 (tampilkan "Sesi berakhir" di layar masuk).
  final bool expired;

  /// "Nanti dulu" di gerbang verifikasi sudah dipilih (gerbang tidak ditampilkan lagi).
  final bool verificationGateSeen;

  bool get isAuthenticated => status == SessionStatus.authenticated;
  Role? get activeRole => user?.activeRole;
}

const _prefGateSeen = 'verification_gate_seen';

/// Sumber kebenaran sesi. Feature notifier yang bergantung pada pengguna harus
/// `ref.watch(sessionProvider.select((s) => s.user?.id))` agar reset otomatis saat ganti akun.
class SessionController extends Notifier<SessionState> {
  /// Tujuan yang dilanjutkan setelah masuk lagi (diisi router, dikonsumsi sekali).
  String? returnTo;

  String? takeReturnTo() {
    final r = returnTo;
    returnTo = null;
    return r;
  }

  @override
  SessionState build() {
    Future.microtask(bootstrap);
    return const SessionState();
  }

  void _set(SessionState s) {
    if (ref.mounted) state = s;
  }

  Future<void> bootstrap() async {
    try {
      final token = await ref.read(tokenStoreProvider).read();
      if (token == null) {
        return _set(const SessionState(status: SessionStatus.unauthenticated));
      }
      final user = await ref.read(authRepositoryProvider).me();
      _set(_authed(user));
    } on ApiException catch (e) {
      // 401 = token mati -> hapus. Jaringan putus = biarkan token, minta masuk lagi.
      if (e.isUnauthorized) await ref.read(tokenStoreProvider).clear();
      _set(
        SessionState(
          status: SessionStatus.unauthenticated,
          expired: e.isUnauthorized,
        ),
      );
    } on Object {
      // Keychain/Keystore rusak atau respons tak terduga: jangan biarkan splash menggantung.
      _set(const SessionState(status: SessionStatus.unauthenticated));
    }
  }

  SessionState _authed(AuthUser user) => SessionState(
    status: SessionStatus.authenticated,
    user: user,
    verificationGateSeen:
        ref.read(prefsProvider).getBool(_prefGateSeen) ?? false,
  );

  /// Dipanggil setelah verifyOtp/login sukses.
  Future<void> signIn(AuthSession session) async {
    await ref.read(tokenStoreProvider).write(session.token);
    _set(_authed(session.user));
  }

  Future<void> refreshUser() async {
    final user = await ref.read(authRepositoryProvider).me();
    _set(
      SessionState(
        status: SessionStatus.authenticated,
        user: user,
        verificationGateSeen: state.verificationGateSeen,
      ),
    );
  }

  Future<void> setRoles(Set<Role> roles) async =>
      _update(await ref.read(authRepositoryProvider).setRoles(roles));

  Future<void> switchRole(Role role) async =>
      _update(await ref.read(authRepositoryProvider).switchRole(role));

  Future<void> uploadPhoto(String path) async =>
      _update(await ref.read(authRepositoryProvider).uploadPhoto(path));

  Future<void> removePhoto() async =>
      _update(await ref.read(authRepositoryProvider).removePhoto());

  void _update(AuthUser user) => _set(
    SessionState(
      status: SessionStatus.authenticated,
      user: user,
      verificationGateSeen: state.verificationGateSeen,
    ),
  );

  Future<void> markVerificationGateSeen() async {
    await ref.read(prefsProvider).setBool(_prefGateSeen, true);
    _set(
      SessionState(
        status: SessionStatus.authenticated,
        user: state.user,
        verificationGateSeen: true,
      ),
    );
  }

  /// Panggil API lalu hapus token + cache lokal WALAU request gagal (MOB-SEC-20).
  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } on Object {
      // tetap lanjut bersihkan lokal
    }
    await _clearLocal();
    _set(const SessionState(status: SessionStatus.unauthenticated));
  }

  /// 401 global: sesi dicabut server.
  Future<void> expire() async {
    if (state.status != SessionStatus.authenticated) return;
    await _clearLocal();
    _set(
      const SessionState(status: SessionStatus.unauthenticated, expired: true),
    );
  }

  Future<void> _clearLocal() async {
    await ref.read(tokenStoreProvider).clear();
    final prefs = ref.read(prefsProvider);
    await prefs.remove(_prefGateSeen);
    // draf lamaran + penanda kesepakatan milik pengguna sebelumnya tak boleh terbawa ke akun berikutnya
    for (final k in prefs.getKeys().toList()) {
      if (k.startsWith('apply_draft_') || k.startsWith('agreement_seen_')) {
        await prefs.remove(k);
      }
    }
    // foto sensitif tak boleh tertinggal pada logout/401/revoke (MOB-SEC-20)
    try {
      await sweepSensitiveFiles();
    } on Object {
      // dibersihkan pada start berikutnya
    }
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
