import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthDataSource {
  /// Si el servidor no responde en ese plazo, la llamada aborta con un error
  /// amigable en lugar de dejar el spinner girando para siempre.
  static const _requestTimeout = Duration(seconds: 20);

  final SupabaseClient _client;

  SupabaseAuthDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  GoTrueClient get _auth => _client.auth;

  /// Stream de cambios de sesion (sign-in, sign-out, token refresh y callback
  /// de OAuth). Fuente de verdad del flujo OAuth: cuando el navegador vuelve
  /// por el deep link, la sesion se completa aqui.
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return await _auth
        .signUp(
          email: email,
          password: password,
          data: {'display_name': displayName},
        )
        .timeout(_requestTimeout);
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth
        .signInWithPassword(email: email, password: password)
        .timeout(_requestTimeout);
  }

  Future<bool> signInWithGoogle() async {
    return await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.rivalfit.rivalfit://login-callback',
    );
  }

  Future<bool> signInWithApple() async {
    return await _auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'com.rivalfit.rivalfit://login-callback',
    );
  }

  Future<bool> signInWithFacebook() async {
    return await _auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'com.rivalfit.rivalfit://login-callback',
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Envia el email de recuperacion con el codigo OTP de 6 digitos
  /// (GOTRUE_MAILER_OTP_EXP=600 en el backend). Responde 200 identico para
  /// emails inexistentes (anti-enumeracion servida por GoTrue).
  Future<void> sendRecoveryCode(String email) async {
    await _auth.resetPasswordForEmail(email).timeout(_requestTimeout);
  }

  /// Valida el codigo OTP de recuperacion. Si es correcto, GoTrue entrega una
  /// sesion temporal de recovery con la que se podra actualizar la clave.
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    final response = await _auth
        .verifyOTP(
          email: email,
          token: code,
          type: OtpType.recovery,
        )
        .timeout(_requestTimeout);
    if (response.session == null) {
      throw const AuthException('No se pudo verificar el código. Inténtalo de nuevo.');
    }
  }

  /// Actualiza la clave del usuario autenticado con la sesion temporal de
  /// recovery obtenida tras verificar el codigo.
  Future<void> updatePassword(String newPassword) async {
    await _auth
        .updateUser(UserAttributes(password: newPassword))
        .timeout(_requestTimeout);
  }

  /// Actualiza el user_metadata del usuario autenticado.
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    await _auth.updateUser(UserAttributes(data: metadata));
  }

  /// Sube la foto de perfil al bucket 'avatars' y devuelve su URL publica.
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('No autenticado');
    }
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final path =
        'public/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage
        .from('avatars')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: false));
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  User? getCurrentSupabaseUser() {
    final session = _auth.currentSession;
    if (session == null) return null;
    return _auth.currentUser;
  }
}
