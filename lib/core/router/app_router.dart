import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/role_shell.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/application/presentation/application_routes.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/auth/presentation/auth_routes.dart';
import 'package:pramu_apps/features/booking/presentation/booking_routes.dart';
import 'package:pramu_apps/features/chat/presentation/chat_routes.dart';
import 'package:pramu_apps/features/home/presentation/home_routes.dart';
import 'package:pramu_apps/features/interview/presentation/interview_routes.dart';
import 'package:pramu_apps/features/listing/presentation/listing_routes.dart';
import 'package:pramu_apps/features/notification/presentation/notification_routes.dart';
import 'package:pramu_apps/features/payment/presentation/payment_routes.dart';
import 'package:pramu_apps/features/profile/presentation/profile_routes.dart';
import 'package:pramu_apps/features/rating/presentation/rating_routes.dart';
import 'package:pramu_apps/features/report/presentation/report_routes.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/features/verification/presentation/verification_routes.dart';
import 'package:pramu_apps/features/wallet/presentation/wallet_routes.dart';

const _splash = '/splash';
const _ulidQueryKeys = ['listing', 'booking', 'period', 'draft'];

/// Semua rute fitur. Router memilah: path tab -> cabang shell, sisanya -> layar penuh.
final List<RouteBase> allFeatureRoutes = [
  ...authRoutes,
  ...verificationRoutes,
  ...homeRoutes,
  ...notificationRoutes,
  ...profileRoutes,
  ...listingRoutes,
  ...applicationRoutes,
  ...interviewRoutes,
  ...chatRoutes,
  ...bookingRoutes,
  ...paymentRoutes,
  ...walletRoutes,
  ...ratingRoutes,
  ...reportRoutes,
];

GoRoute _routeAt(List<RouteBase> routes, String path) =>
    routes.whereType<GoRoute>().firstWhere((r) => r.path == path);

final _ulidClass = RegExp(r'^[0-7][0-9A-HJKMNP-TV-Z]{25}$');

/// Allowlist deep link dibentuk dari pohon rute itu sendiri (satu sumber kebenaran).
List<RegExp> allowedPatterns(List<RouteBase> routes) => [
  RegExp('^/\$'),
  for (final r in routes.whereType<GoRoute>())
    RegExp(
      '^${r.path.split('/').map((s) => s.startsWith(':') ? '[0-7][0-9A-HJKMNP-TV-Z]{25}' : RegExp.escape(s)).join('/')}\$',
    ),
];

/// Apakah [uri] boleh dibuka (path dikenal, parameter ULID valid). Dipakai untuk deep link/push.
bool isAllowedLocation(Uri uri, List<RegExp> patterns) {
  final path = uri.path.isEmpty ? '/' : uri.path;
  if (path == _splash || !patterns.any((p) => p.hasMatch(path))) {
    return path == _splash;
  }
  for (final k in _ulidQueryKeys) {
    final v = uri.queryParameters[k];
    if (v != null && !_ulidClass.hasMatch(v)) return false;
  }
  return true;
}

String? appRedirect(
  SessionState s,
  Uri uri,
  String? Function() takeReturnTo,
  void Function(String) rememberReturnTo,
  List<RegExp> patterns,
) {
  final loc = uri.path.isEmpty ? '/' : uri.path;

  if (s.status == SessionStatus.booting) {
    if (loc != _splash && loc != '/' && isAllowedLocation(uri, patterns)) {
      rememberReturnTo(uri.toString());
    }
    return loc == _splash ? null : _splash;
  }

  if (!s.isAuthenticated) {
    if (Routes.publicPaths.contains(loc)) return null;
    if (loc != _splash && loc != '/' && isAllowedLocation(uri, patterns)) {
      rememberReturnTo(uri.toString());
    }
    return Routes.welcome;
  }

  final user = s.user!;
  final role = user.activeRole;
  if (role == null) return loc == Routes.pickRole ? null : Routes.pickRole;
  final home = Routes.home(role);

  if (loc == '/' || loc == _splash || Routes.publicPaths.contains(loc)) {
    return takeReturnTo() ?? home;
  }
  if (!isAllowedLocation(uri, patterns)) return home;
  if (loc.startsWith(Routes.seekerPrefix) && role != Role.seeker) return home;
  if (loc.startsWith(Routes.assistantPrefix) && role != Role.assistant) {
    return home;
  }

  final isTabRoot = tabsFor(role).any((t) => t.path == loc);
  if (isTabRoot &&
      user.verification == VerificationStatus.none &&
      !s.verificationGateSeen) {
    return Routes.verificationGate;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final tabPaths = {...seekerTabs, ...assistantTabs}.map((t) => t.path).toSet();
  final patterns = allowedPatterns(allFeatureRoutes);
  final ctrl = ref.read(sessionProvider.notifier);

  StatefulShellRoute shellFor(Role role) => StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => RoleShell(role: role, shell: shell),
    branches: [
      for (final t in tabsFor(role))
        StatefulShellBranch(routes: [_routeAt(allFeatureRoutes, t.path)]),
    ],
  );

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) => appRedirect(
      ref.read(sessionProvider),
      state.uri,
      ctrl.takeReturnTo,
      (v) => ctrl.returnTo = v,
      patterns,
    ),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => null, // dialihkan global redirect
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: _splash,
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      shellFor(Role.seeker),
      shellFor(Role.assistant),
      for (final r in allFeatureRoutes)
        if (!(r is GoRoute && tabPaths.contains(r.path))) r,
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
