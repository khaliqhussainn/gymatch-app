import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/home/gym_detail_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/profile/saved_gyms_screen.dart';
import '../screens/partner/partner_profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String main = '/main';
  static const String home = '/main/home';
  static const String explore = '/main/explore';
  static const String map = '/main/map';
  static const String profile = '/main/profile';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String gymDetail = '/gym-detail';
  static const String search = '/search';
  static const String savedGyms = '/saved-gyms';
  static const String partnerProfile = '/partner-profile';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  redirect: (context, state) {
    // Handle deep links
    final uri = state.uri;
    if (uri.path.startsWith('/reset-password')) {
      final token = uri.queryParameters['token'];
      if (token != null) {
        return '${AppRoutes.resetPassword}?token=$token';
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.gymDetail,
      builder: (context, state) {
        // Receive gymId as extra (int) or fall back to null for static demo
        final gymId = state.extra as int?;
        return GymDetailScreen(gymId: gymId);
      },
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.savedGyms,
      builder: (context, state) => const SavedGymsScreen(),
    ),
    GoRoute(
      path: AppRoutes.partnerProfile,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return PartnerProfileScreen(
          partner: args['partner'] as Map<String, dynamic>,
          gymId: args['gymId'] as int,
          gymName: args['gymName'] as String? ?? '',
        );
      },
    ),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.explore,
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: AppRoutes.map,
          builder: (context, state) => const MapScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
