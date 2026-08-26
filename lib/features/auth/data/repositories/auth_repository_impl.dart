import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:autohost/features/auth/domain/entities/user.dart' as domain;
import 'package:autohost/features/auth/domain/repositories/auth_repository.dart';
import 'package:autohost/core/error/failures.dart';
import 'package:autohost/features/auth/data/datasources/supabase_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<({domain.User? user, Failure? error})> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await dataSource.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      final user = _mapUser(response.user);
      return (user: user, error: null);
    } on supabase.AuthException catch (e) {
      return (user: null, error: AuthFailure(message: e.message));
    } catch (e) {
      return (user: null, error: ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<({domain.User? user, Failure? error})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dataSource.signInWithEmail(
        email: email,
        password: password,
      );
      final user = _mapUser(response.user);
      return (user: user, error: null);
    } on supabase.AuthException catch (e) {
      return (user: null, error: AuthFailure(message: e.message));
    } catch (e) {
      return (user: null, error: ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<({domain.User? user, Failure? error})> signInWithGoogle() async {
    try {
      await dataSource.signInWithGoogle();
      final user = _mapUser(dataSource.getCurrentSupabaseUser());
      return (user: user, error: null);
    } on supabase.AuthException catch (e) {
      return (user: null, error: AuthFailure(message: e.message));
    } catch (e) {
      return (user: null, error: ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<({domain.User? user, Failure? error})> signInWithApple() async {
    try {
      await dataSource.signInWithApple();
      final user = _mapUser(dataSource.getCurrentSupabaseUser());
      return (user: user, error: null);
    } on supabase.AuthException catch (e) {
      return (user: null, error: AuthFailure(message: e.message));
    } catch (e) {
      return (user: null, error: ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<({domain.User? user, Failure? error})> signInWithFacebook() async {
    try {
      await dataSource.signInWithFacebook();
      final user = _mapUser(dataSource.getCurrentSupabaseUser());
      return (user: user, error: null);
    } on supabase.AuthException catch (e) {
      return (user: null, error: AuthFailure(message: e.message));
    } catch (e) {
      return (user: null, error: ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Failure?> signOut() async {
    try {
      await dataSource.signOut();
      return null;
    } catch (e) {
      return ServerFailure(message: e.toString());
    }
  }

  @override
  Future<({domain.User? user, Failure? error})> getCurrentUser() async {
    try {
      final sbUser = dataSource.getCurrentSupabaseUser();
      if (sbUser == null) {
        return (user: null, error: AuthFailure(message: 'No autenticado'));
      }
      final user = _mapUser(sbUser);
      return (user: user, error: null);
    } catch (e) {
      return (user: null, error: ServerFailure(message: e.toString()));
    }
  }

  domain.User? _mapUser(supabase.User? sbUser) {
    if (sbUser == null) return null;
    final metadata = sbUser.userMetadata ?? {};
    return domain.User(
      id: sbUser.id,
      displayName: metadata['display_name'] ?? sbUser.email?.split('@').first ?? '',
      email: sbUser.email ?? '',
      photoUrl: metadata['avatar_url'],
      authProvider: _mapProvider(sbUser.appMetadata['provider']),
      createdAt: DateTime.parse(sbUser.createdAt),
    );
  }

  domain.AuthProviderType _mapProvider(String? provider) {
    switch (provider) {
      case 'google':
        return domain.AuthProviderType.google;
      case 'facebook':
        return domain.AuthProviderType.facebook;
      case 'apple':
        return domain.AuthProviderType.apple;
      default:
        return domain.AuthProviderType.email;
    }
  }
}
