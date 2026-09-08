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

  Future<({User? user, Failure? error})> getCurrentUser();

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
