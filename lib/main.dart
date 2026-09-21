import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'app/router.dart';
import 'app/theme/app_theme.dart';
import 'core/deeplinks/deep_link.dart';
import 'core/deeplinks/deep_link_parser.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/controllers/auth_providers.dart';
import 'features/auth/presentation/controllers/recovery_controller.dart';
import 'features/league/presentation/controllers/league_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://fit-api.iscx.site'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: ''),
    // PKCE: flujo OAuth que devuelve la sesion por el deep link
    // com.rivalfit.rivalfit://login-callback. El plugin de supabase_flutter
    // escucha el deep link (app_links) y restaura la sesion persistida antes
    // de que la UI arranque; los cambios se propagan via onAuthStateChange.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(
    ProviderScope(
      child: const RivalFitApp(),
    ),
  );
}

class RivalFitApp extends ConsumerStatefulWidget {
  const RivalFitApp({super.key});

  @override
  ConsumerState<RivalFitApp> createState() => _RivalFitAppState();
}

class _RivalFitAppState extends ConsumerState<RivalFitApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  String? _lastSignature;
  DateTime? _lastHandledAt;

  @override
  void initState() {
    super.initState();
    _listenDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _listenDeepLinks() async {
    _linkSub = _appLinks.uriLinkStream.listen(_handleUri, onError: (_) {});
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (_) {
      // Sin enlace inicial: arranque normal.
    }
  }

  /// Resuelve los enlaces que abren la app:
  ///
  /// * Invitacion a liga (host=join u https://fit-api.iscx.site/join/CODE).
  /// * Recuperacion de contrasena (com.rivalfit.rivalfit://reset?.. o el
  ///   enlace https /reset?..): prellena y verifica el codigo OTP.
  ///
  /// Un mismo enlace puede emitirse dos veces (initial link + stream), por eso
  /// se deduplica por firma dentro de una ventana corta.
  void _handleUri(Uri uri) {
    final action = const DeepLinkParser().parse(uri);
    if (action == null) return;

    switch (action.kind) {
      case DeepLinkKind.join:
        final joinCode = action.joinCode;
        if (joinCode == null) return;
        if (!_claimLink('join|$joinCode')) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final auth = ref.read(authControllerProvider);
          if (auth.status == AuthStatus.authenticated) {
            ref.read(routerProvider).go('/join/$joinCode');
          } else {
            // Sin sesion: guardamos el codigo y pasamos por login. Cuando la
            // sesion se complete (ver _checkPendingJoin), abrimos la invitacion.
            ref
                .read(leagueControllerProvider.notifier)
                .setPendingJoinCode(joinCode);
            ref.read(routerProvider).go('/login');
          }
        });
        return;

      case DeepLinkKind.reset:
        final email = action.email;
        final code = action.recoveryCode;
        if (email == null ||
            code == null ||
            code.length != recoveryOtpLength) {
          return;
        }
        if (!_claimLink('$email|$code')) return;

        // Marca la sesion como "en recuperacion" ANTES de navegar: el guard del
        // router solo deja entrar a /recover si isRecovering ya es true.
        ref.read(authControllerProvider.notifier).setRecovering(true);
        ref.read(recoveryControllerProvider.notifier).startFromLink(
              email: email,
              code: code,
            );

        // En arranque en frio el GoRouter aun no esta montado cuando initState
        // resuelve el enlace inicial; navegar en el siguiente frame evita que
        // initialLocation('/onboarding') adelante a la navegacion.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(routerProvider).go('/recover');
        });
        return;

      case DeepLinkKind.loginCallback:
        // Callback OAuth (PKCE): lo consume supabase_flutter, no es accion.
        return;
    }
  }

  /// Marca el enlace como atendido. Devuelve false si ya se proceso una firma
  /// identica en los ultimos 3 segundos (initial link + stream duplicados).
  bool _claimLink(String signature) {
    final now = DateTime.now();
    if (_lastSignature == signature &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 3)) {
      return false;
    }
    _lastSignature = signature;
    _lastHandledAt = now;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Invitacion pendiente: si el usuario se loguea (o termina el perfil y
    // vuelve al home), se abre la pagina de invitacion guardada.
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      final wasAuthed = prev?.status == AuthStatus.authenticated;
      if (!wasAuthed && next.status == AuthStatus.authenticated) {
        final pending =
            ref.read(leagueControllerProvider).pendingJoinCode;
        if (pending != null && mounted) {
          context.go('/join/$pending');
        }
      }
    });
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RivalFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
