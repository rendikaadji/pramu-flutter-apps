import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/application/presentation/screens/applicant_screen.dart';
import 'package:pramu_apps/features/application/presentation/screens/application_detail_screen.dart';
import 'package:pramu_apps/features/application/presentation/screens/apply_screen.dart';
import 'package:pramu_apps/features/application/presentation/screens/invite_screen.dart';
import 'package:pramu_apps/features/application/presentation/screens/my_applications_screen.dart';

final List<RouteBase> applicationRoutes = [
  GoRoute(
    path: Routes.inviteT,
    builder: (context, state) =>
        InviteScreen(assistantId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.applyT,
    builder: (context, state) =>
        ApplyScreen(listingId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.applicantT,
    builder: (context, state) =>
        ApplicantScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.assistantJobs,
    builder: (context, state) => const MyApplicationsScreen(),
  ),
  GoRoute(
    path: Routes.applicationDetailT,
    builder: (context, state) =>
        ApplicationDetailScreen(id: state.pathParameters['id']!),
  ),
];
