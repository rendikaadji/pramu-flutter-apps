import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/payment/presentation/screens/cancel_booking_screen.dart';
import 'package:pramu_apps/features/payment/presentation/screens/confirm_complete_screen.dart';
import 'package:pramu_apps/features/payment/presentation/screens/pay_screen.dart';
import 'package:pramu_apps/features/payment/presentation/screens/payment_status_screen.dart';

/// Layar payment: M-74..M-77 + return Xendit.
final List<RouteBase> paymentRoutes = [
  GoRoute(
    path: Routes.periodPayT,
    builder: (context, state) =>
        PayScreen(periodId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.periodStatusT,
    builder: (context, state) =>
        PaymentStatusScreen(periodId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.periodConfirmT,
    builder: (context, state) =>
        ConfirmCompleteScreen(periodId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.bookingCancelT,
    builder: (context, state) =>
        CancelBookingScreen(bookingId: state.pathParameters['id']!),
  ),
  // Return dari Xendit: hanya pemicu cek status, parameter tidak dipercaya (MOB-SEC-02).
  GoRoute(
    path: Routes.payReturn,
    redirect: (context, state) {
      final p = state.uri.queryParameters['period'];
      return isUlid(p) ? Routes.periodStatus(p!) : '/';
    },
  ),
];
