import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/verification/presentation/screens/capture_screens.dart';
import 'package:pramu_apps/features/verification/presentation/screens/gate_screens.dart';
import 'package:pramu_apps/features/verification/presentation/screens/review_screen.dart';
import 'package:pramu_apps/features/verification/presentation/screens/status_screens.dart';

/// M-10..M-16. Foto KTP/selfie hanya di memori + direktori internal (lihat photo_service).
final List<RouteBase> verificationRoutes = [
  GoRoute(
    path: Routes.verificationGate,
    builder: (_, _) => const VerificationGateScreen(),
  ),
  GoRoute(
    path: Routes.verificationGuide,
    builder: (_, _) => const VerificationGuideScreen(),
  ),
  GoRoute(path: Routes.verificationKtp, builder: (_, _) => const KtpScreen()),
  GoRoute(
    path: Routes.verificationSelfie,
    builder: (_, _) => const SelfieScreen(),
  ),
  GoRoute(
    path: Routes.verificationReview,
    builder: (_, _) => const ReviewScreen(),
  ),
  GoRoute(
    path: Routes.verificationStatus,
    builder: (_, _) => const VerificationStatusScreen(),
  ),
  GoRoute(
    path: Routes.skck,
    builder: (_, state) =>
        SkckScreen(listingId: state.uri.queryParameters['listing']),
  ),
];
