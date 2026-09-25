import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/app/route_keeper.dart';
import 'package:rivalfit/core/error/failures.dart';
import 'package:rivalfit/features/auth/domain/entities/user.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_providers.dart';
import 'package:rivalfit/features/auth/domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool profileSkippedThisSession;

  /// True mientras el usuario esta dentro del flujo de recuperacion de
  /// contrasena. Evita que la sesion temporal creada por verifyOTP(type:
  /// recovery) saque al usuario de /recover y lo mande a /home.
  final bool isRecovering;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.profileSkippedThisSession = false,
    this.isRecovering = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Object? errorMessage = _unset,
    bool? profileSkippedThisSession,
    bool? isRecovering,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      profileSkippedThisSession:
          profileSkippedThisSession ?? this.profileSkippedThisSession,
      isRecovering: isRecovering ?? this.isRecovering,
    );
  }

  static const _unset = Object();
}

class AuthController extends StateNotifier<AuthState> with WidgetsBindingObserver {
  /// Si el OAuth se cancela o el navegador nunca redirige por el deep link,
  /// volvemos a unauthenticated para que el boton no quede congelado en loading.
  static const _oauthTimeout = Duration(seconds: 60);
  final AuthRepository _repo;
  StreamSubscription<User?>? _authSubscription;
  Timer? _oauthTimeoutTimer;
  bool _oauthInFlight = false;

  AuthController(this._repo) : super(const AuthState()) {
    WidgetsBinding.instance.addObserver(this);
    // Restaura la sesion ya cargada por supabase_flutter (initialize) de forma
    // SINCRONA, antes del primer frame del router. Asi el primer redirect ya
    // resuelve a /home u /onboarding directo: sin splash ni destello.
    _bootstrapSync();
    _listenToAuthChanges();
  }

  void _bootstrapSync() {
    final user = _repo.currentUserSnapshot;
    // ignore: avoid_print
    print('[diag] bootstrapSync user: ${user == null ? "null" : user.email}');
    state = user != null
        ? AuthState(status: AuthStatus.authenticated, user: user)
        : const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Cuando la app vuelve al frente tras el navegador de OAuth, el deep link
  /// ya tuvo oportunidad de completar la sesion. Si sigue colgada en loading,
  /// soltamos el estado para que el boton no quede girando.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed && _oauthInFlight) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_oauthInFlight && state.status == AuthStatus.loading) {
          _oauthInFlight = false;
          _oauthTimeoutTimer?.cancel();
          unawaited(RouteKeeper.clearOAuthPending());
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      });
    }
  }

  /// Mantiene el estado sincronizado con Supabase. Esto es lo que resuelve el
  /// flujo OAuth: cuando el navegador regresa por el deep link
  /// (com.rivalfit.rivalfit://login-callback), supabase_flutter completa la
  /// sesion y emite un evento aqui.
  void _listenToAuthChanges() {
    _authSubscription = _repo.onAuthStateChange.listen(
      (user) {
        _oauthInFlight = false;
        _oauthTimeoutTimer?.cancel();
        unawaited(RouteKeeper.clearOAuthPending());
        // Preservar isRecovering: este evento dispara cuando verifyOTP crea la
        // sesion temporal de recovery y no debe romper el guard del router.
        state = AuthState(
          status: user != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          user: user,
          isRecovering: state.isRecovering,
        );
        // ignore: avoid_print
        print(
            '[auth] ${DateTime.now().millisecondsSinceEpoch} usuario=${user == null ? "null" : user.email}');
      },
      onError: (Object error) {
        _oauthInFlight = false;
        _oauthTimeoutTimer?.cancel();
        unawaited(RouteKeeper.clearOAuthPending());
        if (state.status == AuthStatus.loading) {
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _oauthTimeoutTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _repo.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (result.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: result.user,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: result.error?.message ?? 'Error al crear cuenta',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _friendlyUnexpected(e),
      );
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _repo.signInWithEmail(
        email: email,
        password: password,
      );
      if (result.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: result.user,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: result.error?.message ?? 'Error al iniciar sesion',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _friendlyUnexpected(e),
      );
    }
  }

  /// Nunca dejar el estado colgado en loading ante un error imprevisto.
  String _friendlyUnexpected(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('timeout') || raw.contains('socket') || raw.contains('connection')) {
      return 'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }

  /// Lanza un flujo OAuth. El estado queda en loading hasta que
  /// onAuthStateChange resuelva la sesion cuando el navegador regresa por el
  /// deep link. Solo se marca error si abrir el flujo fallo.
  Future<void> _launchOAuth(
    Future<({User? user, Failure? error})> Function() launch,
  ) async {
    if (_oauthInFlight) return;
    if (!await RouteKeeper.allowOAuthLaunch()) {
      return;
    }
    _oauthInFlight = true;
    state = state.copyWith(status: AuthStatus.loading);
    _oauthTimeoutTimer?.cancel();
    _oauthTimeoutTimer = Timer(_oauthTimeout, () {
      if (state.status == AuthStatus.loading) {
        _oauthInFlight = false;
        unawaited(RouteKeeper.clearOAuthPending());
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    });

    await RouteKeeper.markOAuthPending();
    final result = await launch();
    if (result.error != null) {
      _oauthInFlight = false;
      _oauthTimeoutTimer?.cancel();
      unawaited(RouteKeeper.clearOAuthPending());
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: result.error!.message,
      );
    }
  }

  Future<void> signInWithGoogle() => _launchOAuth(_repo.signInWithGoogle);

  Future<void> signInWithFacebook() => _launchOAuth(_repo.signInWithFacebook);

  Future<void> signInWithApple() => _launchOAuth(_repo.signInWithApple);

  Future<void> signOut() async {
    await _repo.signOut();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      profileSkippedThisSession: false,
    );
  }

  /// Marca/desmarca el flujo de recuperacion de contrasena. Mientras este
  /// activo, el router permite permanecer en /recover incluso con una sesion
  /// temporal de recovery activa.
  void setRecovering(bool value) {
    if (state.isRecovering == value) return;
    state = state.copyWith(isRecovering: value);
  }

  /// Guarda el perfil completo. Al persistir is_profile_complete = true,
  /// el router redirige a /home automaticamente.
  Future<void> completeProfile({
    required String displayName,
    required FitnessLevel fitnessLevel,
    required double weightKg,
    required int heightCm,
    String? avatarUrl,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.completeProfile(
      displayName: displayName,
      fitnessLevel: fitnessLevel,
      weightKg: weightKg,
      heightCm: heightCm,
      avatarUrl: avatarUrl,
    );
    if (result.user != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: result.error?.message ?? 'Error al guardar perfil',
      );
    }
  }

  /// Persiste is_profile_complete = false y permite esta sesion llegar a /home.
  Future<void> skipProfile() async {
    await _repo.skipProfile();
    state = state.copyWith(profileSkippedThisSession: true);
  }

  /// Sube la foto de perfil (no bloquea la UI). Devuelve la URL publica si
  /// tiene exito y, en caso de fallo, un mensaje legible para el usuario.
  Future<({String? url, String? error})> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (state.status != AuthStatus.authenticated) {
      return (url: null, error: 'No autenticado');
    }
    final result = await _repo.uploadAvatar(bytes: bytes, fileName: fileName);
    if (result.url != null) return (url: result.url, error: null);
    return (url: null, error: result.error?.message ?? 'No se pudo subir la foto');
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});