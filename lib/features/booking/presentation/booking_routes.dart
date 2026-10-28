import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/booking/presentation/screens/agreement_form_screen.dart';
import 'package:pramu_apps/features/booking/presentation/screens/agreement_review_screen.dart';
import 'package:pramu_apps/features/booking/presentation/screens/booking_detail_screen.dart';
import 'package:pramu_apps/features/booking/presentation/screens/cancel_booking_screen.dart';
import 'package:pramu_apps/features/booking/presentation/screens/contracts_screen.dart';

/// Layar booking: M-70..M-73 dan M-77 (batal).
final List<RouteBase> bookingRoutes = [
  GoRoute(
    path: Routes.agreementNewT,
    builder: (context, state) =>
        AgreementFormScreen(applicationId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.agreementReviewT,
    builder: (context, state) =>
        AgreementReviewScreen(agreementId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.contracts,
    builder: (context, state) => const ContractsScreen(),
  ),
  GoRoute(
    path: Routes.bookingDetailT,
    builder: (context, state) =>
        BookingDetailScreen(bookingId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.bookingCancelT,
    builder: (context, state) =>
        CancelBookingScreen(bookingId: state.pathParameters['id']!),
  ),
  // Return Xendit biaya tayang: hanya pemicu cek status, parameter tidak dipercaya (MOB-SEC-02).
  GoRoute(
    path: Routes.payReturn,
    redirect: (context, state) {
      final l = state.uri.queryParameters['listing'];
      return isUlid(l) ? Routes.listingPay(l!) : '/';
    },
  ),
];
