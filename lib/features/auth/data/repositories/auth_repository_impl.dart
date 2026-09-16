import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:rivalfit/features/auth/domain/entities/user.dart' as domain;
import 'package:rivalfit/features/auth/domain/repositories/auth_repository.dart';
import 'package:rivalfit/core/error/failures.dart';
import 'package:rivalfit/features/auth/data/datasources/supabase_auth_data_source.dart';

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
      return (user: null, error: AuthFailure(message: _friendlySignUpMessage(e)));
    } catch (e) {
      return (user: null, error: ServerFailure(message: _friendlyServerMessage(e.toString())));
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
      return (user: null, error: AuthFailure(message: _friendlyLoginMessage(e)));
    } catch (e) {
      return (user: null, error: ServerFailure(message: _friendlyServerMessage(e.toString())));
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
  Future<Failure?> sendRecoveryCode(String email) async {
    try {
      await dataSource.sendRecoveryCode(email);
      return null;
    } on supabase.AuthException catch (e) {
      return AuthFailure(message: _friendlyRecoveryMessage(e));
    } catch (e) {
      return ServerFailure(message: _friendlyServerMessage(e.toString()));
    }
  }

  @override
  Future<Failure?> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    try {
      await dataSource.verifyRecoveryCode(email: email, code: code);
      return null;
    } on supabase.AuthException catch (e) {
      return AuthFailure(message: _friendlyRecoveryMessage(e));
    } catch (e) {
      return ServerFailure(message: _friendlyServerMessage(e.toString()));
    }
  }

  @override
  Future<Failure?> resetPassword(String newPassword) async {
    try {
      await dataSource.updatePassword(newPassword);
      await dataSource.signOut();
      return null;
    } on supabase.AuthException catch (e) {
      return AuthFailure(message: _friendlyRecoveryMessage(e));
    } catch (e) {
      return ServerFailure(message: _friendlyServerMessage(e.toString()));
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

  @override
  Stream<domain.User?> get onAuthStateChange =>
      dataSource.authStateChanges.map((state) => _mapUser(state.session?.user));

  @override
  Future<({domain.User? user, Failure? error})> completeProfile({
    required String displayName,
    required domain.FitnessLevel fitnessLevel,
    required double weightKg,
    required int heightCm,
    String? avatarUrl,
  }) async {
    try {
      await dataSource.updateUserMetadata({
        'display_name': displayName,
        'fitness_level': fitnessLevel.storageValue,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'is_profile_complete': true,
        'avatar_url': ?avatarUrl,
      });
      final user = _mapUser(dataSource.getCurrentSupabaseUser());
      return (user: user, error: null);
    } on supabase.AuthException catch (e) {
      return (user: null, error: AuthFailure(message: e.message));
    } catch (e) {
      return (user: null, error: ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<({domain.User? user, Failure? error})> skipProfile() async {
    try {
      await dataSource.updateUserMetadata({'is_profile_complete': false});
      final user = _mapUser(dataSource.getCurrentSupabaseUser());
      return (user: user, error: null);
    } on supabase.AuthException catch (e) {
      return (user: null, error: AuthFailure(message: e.message));
    } catch (e) {
      return (user: null, error: ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<({String? url, Failure? error})> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final url = await dataSource.uploadAvatar(bytes: bytes, fileName: fileName);
      return (url: url, error: null);
    } on supabase.AuthException catch (e) {
      return (url: null, error: AuthFailure(message: e.message));
    } catch (e) {
      return (url: null, error: ServerFailure(message: e.toString()));
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
      isProfileComplete: metadata['is_profile_complete'] == true,
      fitnessLevel: domain.FitnessLevel.fromStorage(metadata['fitness_level'] as String?),
      weightKg: (metadata['weight_kg'] as num?)?.toDouble(),
      heightCm: (metadata['height_cm'] as num?)?.toInt(),
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

  /// Traduce los codigos de error de GoTrue a mensajes claros para el flujo de
  /// recuperacion. Fuera de estos casos intenta detectar errores de red/gateway
  /// y si no, expone el mensaje crudo del servidor.
  String _friendlyRecoveryMessage(supabase.AuthException e) {
    switch (e.code) {
      case 'otp_expired':
        return 'Código incorrecto o expirado. Solicita uno nuevo.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Demasiadas solicitudes. Espera un momento e inténtalo de nuevo.';
      default:
        return _friendlyServerMessage(e.message);
    }
  }

  /// Detecta errores de conexion (gateway, timeout, decode) y los traduce a
  /// un mensaje en espanol en lugar de exponer el texto crudo del SDK.
  String _friendlyServerMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('failed to decode') ||
        lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('handshake') ||
        lower.contains('network')) {
      return 'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.';
    }
    return raw;
  }

  /// Mensajes claros para el registro. El caso mas comun es intentar crear una
  /// cuenta con un correo que ya existe (GoTrue responde 422 user_already_exists).
  String _friendlySignUpMessage(supabase.AuthException e) {
    final msg = e.message.toLowerCase();
    if (e.code == 'user_already_exists' ||
        msg.contains('already registered') ||
        msg.contains('already been registered')) {
      return 'Este correo ya está registrado. Inicia sesión.';
    }
    if (msg.contains('unable to validate email') ||
        msg.contains('invalid email') ||
        msg.contains('email not allowed')) {
      return 'El correo no es válido. Verifícalo e inténtalo de nuevo.';
    }
    return _friendlyServerMessage(e.message);
  }

  /// Mensajes claros para el inicio de sesion.
  String _friendlyLoginMessage(supabase.AuthException e) {
    final msg = e.message.toLowerCase();
    if (e.code == 'invalid_credentials' ||
        msg.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (e.code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión.';
    }
    return _friendlyServerMessage(e.message);
  }
}
