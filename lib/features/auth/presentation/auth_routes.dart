import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/auth/presentation/screens/account_screen.dart';
import 'package:pramu_apps/features/auth/presentation/screens/devices_screen.dart';
import 'package:pramu_apps/features/auth/presentation/screens/forgot_screen.dart';
import 'package:pramu_apps/features/auth/presentation/screens/login_screen.dart';
import 'package:pramu_apps/features/auth/presentation/screens/otp_screen.dart';
import 'package:pramu_apps/features/auth/presentation/screens/register_screen.dart';
import 'package:pramu_apps/features/auth/presentation/screens/role_screen.dart';
import 'package:pramu_apps/features/auth/presentation/screens/welcome_screen.dart';

/// Layar auth + akun. M-22 (ganti peran) = bottom sheet dari `shared/app_ui/shell_app_bar.dart`.
final List<RouteBase> authRoutes = [
  GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
  GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
  GoRoute(path: Routes.otp, builder: (_, _) => const OtpScreen()),
  GoRoute(path: Routes.pickRole, builder: (_, _) => const RoleScreen()),
  GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
  GoRoute(path: Routes.forgot, builder: (_, _) => const ForgotScreen()),
  GoRoute(path: Routes.account, builder: (_, _) => const AccountScreen()),
  GoRoute(path: Routes.seekerAccount, builder: (_, _) => const AccountScreen()),
  GoRoute(
    path: Routes.assistantAccount,
    builder: (_, _) => const AccountScreen(),
  ),
  GoRoute(path: Routes.devices, builder: (_, _) => const DevicesScreen()),
];
