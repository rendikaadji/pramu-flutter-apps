import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/notification/presentation/screens/notifications_screen.dart';

final List<RouteBase> notificationRoutes = [
  GoRoute(
    path: Routes.notifications,
    builder: (context, state) => const NotificationsScreen(),
  ),
];
