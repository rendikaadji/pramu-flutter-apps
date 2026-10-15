import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/wallet/presentation/screens/bank_screen.dart';
import 'package:pramu_apps/features/wallet/presentation/screens/payout_screen.dart';
import 'package:pramu_apps/features/wallet/presentation/screens/wallet_history_screen.dart';
import 'package:pramu_apps/features/wallet/presentation/screens/wallet_screen.dart';

/// Layar wallet: M-80 (dibuka dari tab Profil), M-81..M-83.
final List<RouteBase> walletRoutes = [
  GoRoute(
    path: Routes.assistantWallet,
    builder: (context, state) => const WalletScreen(),
  ),
  GoRoute(
    path: Routes.payout,
    builder: (context, state) => const PayoutScreen(),
  ),
  GoRoute(path: Routes.bank, builder: (context, state) => const BankScreen()),
  GoRoute(
    path: Routes.walletHistory,
    builder: (context, state) => const WalletHistoryScreen(),
  ),
];
