import 'package:autohost/core/error/failures.dart';
import 'package:autohost/features/auth/domain/entities/user.dart';

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
}
