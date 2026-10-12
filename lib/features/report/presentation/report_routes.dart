import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/report/presentation/screens/privacy_screen.dart';
import 'package:pramu_apps/features/report/presentation/screens/report_form_screen.dart';
import 'package:pramu_apps/features/report/presentation/screens/report_share_screen.dart';
import 'package:pramu_apps/features/report/presentation/screens/report_status_screen.dart';

final List<RouteBase> reportRoutes = [
  GoRoute(path: Routes.privacy, builder: (_, _) => const PrivacyScreen()),
  GoRoute(
    path: Routes.reportNew,
    builder: (_, state) => ReportFormScreen(
      bookingId: state.uri.queryParameters['booking'],
      periodId: state.uri.queryParameters['period'],
      userId: state.uri.queryParameters['user'],
    ),
  ),
  GoRoute(
    path: Routes.reportShareT,
    builder: (_, state) => ReportShareScreen(
      reportId: state.pathParameters['id']!,
      conversationId: state.uri.queryParameters['conversation'],
    ),
  ),
  GoRoute(
    path: Routes.reportStatusT,
    builder: (_, state) =>
        ReportStatusScreen(reportId: state.pathParameters['id']!),
  ),
];
