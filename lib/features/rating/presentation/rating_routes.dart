import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/rating/presentation/screens/rating_screen.dart';
import 'package:pramu_apps/features/rating/presentation/screens/user_reviews_screen.dart';

final List<RouteBase> ratingRoutes = [
  GoRoute(
    path: Routes.ratingT,
    builder: (context, state) =>
        RatingScreen(bookingId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.userReviewsT,
    builder: (context, state) =>
        UserReviewsScreen(userId: state.pathParameters['id']!),
  ),
];
