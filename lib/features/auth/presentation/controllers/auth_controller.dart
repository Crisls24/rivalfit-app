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

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.profileSkippedThisSession = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? profileSkippedThisSession,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      profileSkippedThisSession:
          profileSkippedThisSession ?? this.profileSkippedThisSession,
    );
  }
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
    _init();
    _listenToAuthChanges();
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
        debugPrint('[AUTH] change user=${user != null}');
        _oauthInFlight = false;
        _oauthTimeoutTimer?.cancel();
        state = AuthState(
          status: user != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          user: user,
        );
      },
      onError: (Object error) {
        _oauthInFlight = false;
        _oauthTimeoutTimer?.cancel();
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

  Future<void> _init() async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.getCurrentUser();
    if (result.user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
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
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
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
  }

  /// Lanza un flujo OAuth. El estado queda en loading hasta que
  /// onAuthStateChange resuelva la sesion cuando el navegador regresa por el
  /// deep link. Solo se marca error si abrir el flujo fallo.
  Future<void> _launchOAuth(
    Future<({User? user, Failure? error})> Function() launch,
  ) async {
    if (_oauthInFlight) return;
    if (!await RouteKeeper.allowOAuthLaunch()) {
      debugPrint('[AUTH] oauth launch bloqueado por cooldown');
      return;
    }
    _oauthInFlight = true;
    debugPrint('[AUTH] oauth launch start');
    state = state.copyWith(status: AuthStatus.loading);
    _oauthTimeoutTimer?.cancel();
    _oauthTimeoutTimer = Timer(_oauthTimeout, () {
      if (state.status == AuthStatus.loading) {
        _oauthInFlight = false;
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    });

    final result = await launch();
    debugPrint('[AUTH] oauth launch returned error=${result.error != null}');
    if (result.error != null) {
      _oauthInFlight = false;
      _oauthTimeoutTimer?.cancel();
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
    state = const AuthState(status: AuthStatus.unauthenticated);
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

  /// Sube la foto de perfil (no bloquea la UI). Devuelve null si falla.
  Future<String?> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (state.status != AuthStatus.authenticated) return null;
    final result = await _repo.uploadAvatar(bytes: bytes, fileName: fileName);
    return result.url;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
