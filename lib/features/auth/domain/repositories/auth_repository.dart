import 'dart:typed_data';
import 'package:rivalfit/core/error/failures.dart';
import 'package:rivalfit/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<({User? user, Failure? error})> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<({User? user, Failure? error})> signInWithEmail({
    required String email,
    required String password,
  });

  Future<({User? user, Failure? error})> signInWithGoogle();

  Future<({User? user, Failure? error})> signInWithApple();

  Future<({User? user, Failure? error})> signInWithFacebook();

  Future<Failure?> signOut();

  /// Envia el codigo de recuperacion al email. Devuelve null si la solicitud
  /// fue aceptada (GoTrue responde 200 incluso para emails inexistentes).
  Future<Failure?> sendRecoveryCode(String email);

  /// Valida el codigo OTP de recuperacion y deja lista la sesion temporal de
  /// recovery para actualizar la clave. Devuelve null si el codigo es valido.
  Future<Failure?> verifyRecoveryCode({
    required String email,
    required String code,
  });

  /// Actualiza la clave con la sesion temporal de recovery y la descarta
  /// (signOut). Devuelve null si se actualizo correctamente.
  Future<Failure?> resetPassword(String newPassword);

  Future<({User? user, Failure? error})> getCurrentUser();

  /// Stream de cambios de sesion. Fuente de verdad del flujo OAuth: cuando el
  /// navegador regresa por el deep link, se emite la sesion cerrada. El valor
  /// es null cuando la sesion termina (sign out).
  Stream<User?> get onAuthStateChange;

  /// Guarda el perfil completo y marca is_profile_complete = true.
  Future<({User? user, Failure? error})> completeProfile({
    required String displayName,
    required FitnessLevel fitnessLevel,
    required double weightKg,
    required int heightCm,
    String? avatarUrl,
  });

  /// Persiste is_profile_complete = false (usuario que omitio el paso).
  Future<({User? user, Failure? error})> skipProfile();

  Future<({String? url, Failure? error})> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  });
}
