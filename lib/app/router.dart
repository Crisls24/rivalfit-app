import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rivalfit/features/auth/presentation/pages/onboarding_page.dart';
import 'package:rivalfit/features/auth/presentation/pages/login_page.dart';
import 'package:rivalfit/features/auth/presentation/pages/signup_page.dart';
import 'package:rivalfit/features/home/presentation/pages/home_page.dart';
import 'package:rivalfit/features/profile/presentation/pages/complete_profile_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    // Flujo real: la app arranca en Onboarding. Si hay sesion activa, el
    // redirect lleva directo a /home o a /complete-profile (perfil pendiente).
    initialLocation: '/onboarding',
    redirect: (context, state) =>
        _resolveRedirect(authState, state.matchedLocation),
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
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
        path: '/complete-profile',
        name: 'complete-profile',
        builder: (context, state) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
});

/// Decide a que ruta debe ir el usuario segun su estado de sesion.
String? _resolveRedirect(AuthState auth, String location) {
  // 1) Aun cargando el estado inicial: deja pasar para no parpadear.
  if (auth.status == AuthStatus.loading || auth.status == AuthStatus.initial) {
    return null;
  }

  final isOnboarding = location == '/onboarding';
  final isAuthPage = location == '/login' || location == '/signup';
  final isProfile = location == '/complete-profile';

  // 2) Sin sesion: solo onboarding/login/signup son accesibles.
  if (auth.status != AuthStatus.authenticated) {
    if (isOnboarding || isAuthPage) return null;
    return '/onboarding';
  }

  // 3) Con sesion: fuera de onboarding y de las pantallas de auth.
  if (isOnboarding || isAuthPage) return '/home';

  // 4) Perfil incompleto: forzar /complete-profile antes de /home (a menos
  //    que el usuario eligio "Omitir" en esta sesion).
  final profileComplete = auth.user?.isProfileComplete ?? false;
  if (!profileComplete && !auth.profileSkippedThisSession) {
    if (!isProfile) return '/complete-profile';
    return null;
  }

  // 5) Perfil completo: /complete-profile ya no tiene sentido.
  if (isProfile) return '/home';

  return null;
}