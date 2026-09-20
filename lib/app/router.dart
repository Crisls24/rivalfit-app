import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_providers.dart';
import 'package:rivalfit/features/auth/presentation/controllers/recovery_controller.dart';
import 'package:rivalfit/features/auth/presentation/pages/login_page.dart';
import 'package:rivalfit/features/auth/presentation/pages/onboarding_page.dart';
import 'package:rivalfit/features/auth/presentation/pages/recover_access_page.dart';
import 'package:rivalfit/features/auth/presentation/pages/signup_page.dart';
import 'package:rivalfit/features/exercise/presentation/pages/coming_soon_page.dart';
import 'package:rivalfit/features/home/presentation/pages/home_page.dart';
import 'package:rivalfit/features/league/presentation/pages/league_join_page.dart';
import 'package:rivalfit/features/league/presentation/pages/league_ranking_page.dart';
import 'package:rivalfit/features/profile/presentation/pages/complete_profile_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // El GoRouter se crea UNA sola vez. Si se recreara en cada cambio de estado
  // de auth (registryProvider viendo authControllerProvider), un nuevo GoRouter
  // arranca en initialLocation y tira al usuario a /onboarding justo al
  // presionar un boton social. En su lugar, refreshListenable re-evalua el
  // redirect sin perder la ruta actual.
  final authRefresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (_, _) {
    authRefresh.value++;
  });

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final recoveryStep = ref.read(recoveryControllerProvider).step;
      return _resolveRedirect(
        ref.read(authControllerProvider),
        state.matchedLocation,
        recoveryStep,
      );
    },
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
        path: '/recover',
        name: 'recover',
        builder: (context, state) => const RecoverAccessPage(),
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
      GoRoute(
        path: '/session',
        name: 'session',
        builder: (context, state) => const ComingSoonPage(
          title: 'Empezar entrenamiento',
          icon: Icons.videocam_outlined,
          message:
              'La sesión con cámara y verificación por IA llega en la siguiente fase.',
        ),
      ),
      GoRoute(
        path: '/exercise/:id',
        name: 'exercise',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'ejercicio';
          final title = id[0].toUpperCase() + id.substring(1);
          return ComingSoonPage(
            title: title,
            icon: Icons.sports_gymnastics_outlined,
            message:
                'El tutorial y el conteo verificado para $title llegan en la siguiente fase.',
          );
        },
      ),
      GoRoute(
        path: '/league/ranking',
        name: 'league-ranking',
        builder: (context, state) => const LeagueRankingPage(),
      ),
      GoRoute(
        path: '/join/:code',
        name: 'join',
        builder: (context, state) =>
            LeagueJoinPage(code: state.pathParameters['code'] ?? ''),
      ),
    ],
  );
});

/// Decide a que ruta debe ir el usuario segun su estado de sesion.
String? _resolveRedirect(
  AuthState auth,
  String location,
  RecoveryStep recoveryStep,
) {
  // 1) Aun cargando el estado inicial: deja pasar para no parpadear.
  if (auth.status == AuthStatus.loading || auth.status == AuthStatus.initial) {
    return null;
  }

  final isOnboarding = location == '/onboarding';
  final isAuthPage = location == '/login' || location == '/signup';
  final isRecover = location == '/recover';

  // 1-bis) Guard recuperacion SOLO en los pasos OTP y nueva contrasena. La
  // sesion temporal creada por verifyOTP dispara onAuthStateChange con
  // status=authenticated y un perfil a medio terminar; sin este bloque el
  // router lo echaria a /complete-profile o /home en mitad del cambio de
  // contrasena. En step=success se libera para permitir el regreso a /login.
  final midRecovery =
      auth.isRecovering &&
      (recoveryStep == RecoveryStep.otp ||
          recoveryStep == RecoveryStep.password);
  if (midRecovery) {
    if (isRecover) return null;
    return '/recover';
  }

  // 2) Sin sesion: solo onboarding/login/signup/recover son accesibles.
  if (auth.status != AuthStatus.authenticated) {
    if (isOnboarding || isAuthPage || isRecover) return null;
    return '/onboarding';
  }

  // 3) Con sesion: fuera de onboarding y de las pantallas de auth.
  if (isOnboarding || isAuthPage || isRecover) return '/home';

  // 4) Perfil incompleto: forzar /complete-profile antes de /home (a menos
  //    que el usuario eligio "Omitir" en esta sesion).
  final profileComplete = auth.user?.isProfileComplete ?? false;
  if (!profileComplete && !auth.profileSkippedThisSession) {
    if (!isProfile(location)) return '/complete-profile';
    return null;
  }

  // 5) Perfil completo: /complete-profile ya no tiene sentido.
  if (isProfile(location)) return '/home';

  return null;
}

bool isProfile(String location) => location == '/complete-profile';
