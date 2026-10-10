import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/listing/presentation/screens/assistant_search_screen.dart';
import 'package:pramu_apps/features/profile/presentation/screens/assistant_profile_screen.dart';
import 'package:pramu_apps/features/profile/presentation/screens/profile_edit_screen.dart';

/// M-31 dan M-40. M-30 (Cari asisten) = layar fitur listing (satu-satunya impor lintas fitur).
final List<RouteBase> profileRoutes = [
  GoRoute(
    path: Routes.seekerSearch,
    builder: (_, _) => const AssistantSearchScreen(),
  ),
  GoRoute(
    path: Routes.assistantProfileT,
    builder: (_, state) =>
        AssistantProfileScreen(userId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.profileEdit,
    builder: (_, _) => const ProfileEditScreen(),
  ),
];
