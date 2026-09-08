import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthDataSource {
  final SupabaseClient _client;

  SupabaseAuthDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  GoTrueClient get _auth => _client.auth;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(email: email, password: password);
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
