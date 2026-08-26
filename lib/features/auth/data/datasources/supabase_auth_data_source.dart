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
      redirectTo: 'io.autohost://login-callback',
    );
  }

  Future<bool> signInWithApple() async {
    return await _auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.autohost://login-callback',
    );
  }

  Future<bool> signInWithFacebook() async {
    return await _auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'io.autohost://login-callback',
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentSupabaseUser() {
    final session = _auth.currentSession;
    if (session == null) return null;
    return _auth.currentUser;
  }
}
