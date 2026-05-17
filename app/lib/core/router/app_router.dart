import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/expenses/screens/home_screen.dart';
import '../../features/expenses/screens/history_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/budget/screens/budget_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../services/supabase_service.dart';
import 'main_shell.dart';

final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isLoggedIn = supabase.auth.currentUser != null;
    final loc = state.matchedLocation;
    final isAuthRoute = loc.startsWith('/auth') ||
        loc.startsWith('/onboarding') ||
        loc.startsWith('/splash');
    if (!isLoggedIn && !isAuthRoute) return '/auth';
    if (isLoggedIn && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ]),
      ],
    ),
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/budget', builder: (_, __) => const BudgetScreen()),
  ],
);
