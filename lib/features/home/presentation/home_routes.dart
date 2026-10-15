import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/home/presentation/screens/home_screens.dart';

/// M-20 / M-21 (tab root).
final List<RouteBase> homeRoutes = [
  GoRoute(path: Routes.seekerHome, builder: (_, _) => const SeekerHomeScreen()),
  GoRoute(
    path: Routes.assistantHome,
    builder: (_, _) => const AssistantHomeScreen(),
  ),
];
