import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/interview/presentation/screens/confirm_screen.dart';
import 'package:pramu_apps/features/interview/presentation/screens/evaluation_screen.dart';
import 'package:pramu_apps/features/interview/presentation/screens/interview_detail_screen.dart';
import 'package:pramu_apps/features/interview/presentation/screens/propose_screen.dart';

final List<RouteBase> interviewRoutes = [
  GoRoute(
    path: Routes.interviewProposeT,
    builder: (context, state) =>
        ProposeScreen(applicationId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.interviewConfirmT,
    builder: (context, state) => ConfirmScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.interviewDetailT,
    builder: (context, state) =>
        InterviewDetailScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.interviewEvalT,
    builder: (context, state) =>
        EvaluationScreen(id: state.pathParameters['id']!),
  ),
];
