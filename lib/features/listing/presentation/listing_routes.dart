import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/listing/presentation/screens/listing_browse_screen.dart';
import 'package:pramu_apps/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:pramu_apps/features/listing/presentation/screens/listing_manage_screen.dart';
import 'package:pramu_apps/features/listing/presentation/screens/listing_pay_screen.dart';
import 'package:pramu_apps/features/listing/presentation/screens/listing_wizard_screen.dart';
import 'package:pramu_apps/features/listing/presentation/screens/my_listings_screen.dart';

final List<RouteBase> listingRoutes = [
  GoRoute(
    path: Routes.listingNew,
    builder: (context, state) =>
        ListingWizardScreen(draftId: state.uri.queryParameters['draft']),
  ),
  GoRoute(
    path: Routes.listingPayT,
    builder: (context, state) =>
        ListingPayScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.seekerJobs,
    builder: (context, state) => const MyListingsScreen(),
  ),
  GoRoute(
    path: Routes.listingManageT,
    builder: (context, state) =>
        ListingManageScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: Routes.assistantListings,
    builder: (context, state) => const ListingBrowseScreen(),
  ),
  GoRoute(
    path: Routes.listingDetailT,
    builder: (context, state) =>
        ListingDetailScreen(id: state.pathParameters['id']!),
  ),
];
