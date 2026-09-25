import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rivalfit/core/deeplinks/deep_link.dart';
import 'package:rivalfit/core/deeplinks/deep_link_parser.dart';
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

/// Enlace profundo inicial (getInitialLink). NULL en arranque normal. En
/// arranque en frio por OAuth contiene el login-callback de PKCE; se inyecta
/// desde main() ANTES de crear el router para decidir la ruta del primer frame.
final initialDeepLinkProvider = Provider<Uri?>((ref) => null);

/// True si al arrancar habia un OAuth pendiente de resolver (el usuario toco
/// Google y el navegador aun no devuelve la sesion). Se inyecta desde main()
/// leyendo shared_preferences; junto con [initialDeepLinkProvider] garantiza
/// que el primer frame NO sea onboarding cuando venimos de un login social.
final oauthPendingProvider = Provider<bool>((ref) => false);

/// Ruta para el primer frame segun el enlace inicial:
///
/// * [DeepLinkKind.loginCallback] o un OAuth pendiente (vienes de validar
///   Google): arrancar en /login para que el salto a /home ocurra al
///   completarse la sesion, sin pasar por onboarding (si no, en frio se veria
///   onboarding -> home como un fallo).
///
/// * Cualquier otra cosa (null, join, reset, arranque normal): /onboarding.
String initialRouteFor(Uri? initialLink, {required bool oauthPending}) {
  final action =
      initialLink == null ? null : const DeepLinkParser().parse(initialLink);
  if (action?.kind == DeepLinkKind.loginCallback || oauthPending) {
    return '/login';
  }
  return '/onboarding';
}

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
    // En arranque en frio por OAuth arranca en /login (nunca en onboarding);
    // en arranque normal en /onboarding. Se decide con el enlace inicial ANTES
    // del primer frame, asi no destella onboarding al volver de Google.
    // ignore: avoid_print
    initialLocation: () {
      final route = initialRouteFor(
        ref.read(initialDeepLinkProvider),
        oauthPending: ref.read(oauthPendingProvider),
      );
      // ignore: avoid_print
      print('[diag] router inicial: $route');
      return route;
    }(),
    // Ignora el deep link que el SO entrega al arrancar (p. ej. la URI del
    // login-callback de OAuth). Sin esto, go_router intenta resolver
    // `com.rivalfit.rivalfit://login-callback?...` como ruta y muestra
    // "No routes for location". Los deep links reales (join/reset) se
    // atienden via app_links en main.dart, no por el engine del router.
    overridePlatformDefaultLocation: true,
    refreshListenable: authRefresh,
    observers: [_RouteObservingObserver()],
    errorBuilder: (context, state) => const _RouteErrorPage(),
    redirect: (context, state) {
      final recoveryStep = ref.read(recoveryControllerProvider).step;
      final auth = ref.read(authControllerProvider);
      final result = _resolveRedirect(auth, state.matchedLocation, recoveryStep);
      // ignore: avoid_print
      print(
          '[redirect] loc=${state.matchedLocation} status=${auth.status} -> ${result ?? "null"}');
      return result;
    },
    routes: [
      // La URI custom del login-callback de OAuth (`com.rivalfit.rivalfit://
      // login-callback?...`) que Android entrega EN CALIENTE al volver de
      // Chrome se normaliza a `/` (path vacio). En vez de caer en la pantalla
      // de error (que destellaba onboarding mientras la sesion seguia en
      // loading), se trata como ruta valida y se redirige de inmediato a la
      // ruta correcta segun la sesion: /login si todavia esta resolviendose,
      // /home (o /complete-profile) si el OAuth ya confirmo la sesion.
      GoRoute(
        path: '/',
        name: 'oauth-callback-fallback',
        redirect: (context, state) {
          final auth = ref.read(authControllerProvider);
          final step = ref.read(recoveryControllerProvider).step;
          return _resolveRedirect(auth, '/login', step) ?? '/login';
        },
      ),
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
  // 1) Aun cargando el estado inicial: deja pasar para no parpadear. (Con el
  // bootstrap sincrono del AuthController este estado apenas dura un frame.)
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

/// Instrumentacion temporal: imprime cada ruta que pasa a primer plano para
/// diagnosticar el destello de onboarding al volver de OAuth.
class _RouteObservingObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // ignore: avoid_print
    print('[route] ${DateTime.now().millisecondsSinceEpoch} push ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // ignore: avoid_print
    print(
        '[route] ${DateTime.now().millisecondsSinceEpoch} replace ${newRoute?.settings.name} (was ${oldRoute?.settings.name})');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // ignore: avoid_print
    print('[route] ${DateTime.now().millisecondsSinceEpoch} pop ${route.settings.name}');
  }
}

/// Pantalla de emergencia para rutas no reconocidas (p. ej. una URI de deep
/// link custom que llego al router en caliente sin encajar en `/`). Redirige
/// una sola vez a la ruta correcta segun la sesion en lugar de dejar la
/// pantalla roja de go_router. Nunca cae en /onboarding mientras la sesion
/// esta en loading (OAuth en curso): ahi va a /login y deja que
/// onAuthStateChange lo lleve a /home al confirmarse.
class _RouteErrorPage extends ConsumerStatefulWidget {
  const _RouteErrorPage();

  @override
  ConsumerState<_RouteErrorPage> createState() => _RouteErrorPageState();
}

class _RouteErrorPageState extends ConsumerState<_RouteErrorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      final step = ref.read(recoveryControllerProvider).step;
      final destination =
          _resolveRedirect(auth, '/login', step) ?? '/login';
      context.go(destination);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Transparente: no destella ningun color mientras se resuelve la ruta real.
    return const SizedBox.shrink();
  }
}
