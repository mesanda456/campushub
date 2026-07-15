import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isOnAuthScreen =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      // Not logged in, trying to access anything other than login/register -> bounce to login.
      if (!isLoggedIn && !isOnAuthScreen) {
        return '/login';
      }

      // Logged in, but sitting on login/register -> send to dashboard.
      if (isLoggedIn && isOnAuthScreen) {
        return '/dashboard';
      }

      // Otherwise, no redirect needed.
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});