import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AuthState()) {
    _init();
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

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.signInWithGoogle();
    if (result.user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: result.error?.message ?? 'Error con Google',
      );
    }
  }

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
