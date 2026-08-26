import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autohost/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autohost/features/auth/presentation/pages/onboarding_page.dart';
import 'package:autohost/features/auth/presentation/pages/login_page.dart';
import 'package:autohost/features/auth/presentation/pages/signup_page.dart';
import 'package:autohost/features/home/presentation/pages/home_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.loading ||
          authState.status == AuthStatus.initial;

      if (isLoading) return null;
      if (isOnboarding && !isAuthenticated) return null;
      if (!isAuthenticated && !isAuth) return '/login';
      if (isAuthenticated && isAuth) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
});
