/// Acciones que puede representar un URI profundo recibido por la app
/// (App Link https o custom scheme).
enum DeepLinkKind {
  /// Invitacion a una liga: resuelve en /join/:code.
  join,

  /// Recuperacion de contrasena: prellena y verifica el codigo OTP enviado
  /// por correo.
  reset,

  /// Callback OAuth (PKCE). Lo consume el plugin de supabase_flutter; la app
  /// lo ignora como accion propia.
  loginCallback,
}

/// Accion extraida de un URI por [DeepLinkParser].
class DeepLinkAction {
  final DeepLinkKind kind;

  /// Codigo de invitacion, solo para [DeepLinkKind.join].
  final String? joinCode;

  /// Correo decodificado, solo para [DeepLinkKind.reset].
  final String? email;

  /// Codigo OTP en digitos, solo para [DeepLinkKind.reset].
  final String? recoveryCode;

  const DeepLinkAction._({
    required this.kind,
    this.joinCode,
    this.email,
    this.recoveryCode,
  });

  factory DeepLinkAction.join(String code) =>
      DeepLinkAction._(kind: DeepLinkKind.join, joinCode: code);

  factory DeepLinkAction.reset({
    required String email,
    required String recoveryCode,
  }) =>
      DeepLinkAction._(
        kind: DeepLinkKind.reset,
        email: email,
        recoveryCode: recoveryCode,
      );

  const DeepLinkAction.loginCallback()
      : this._(kind: DeepLinkKind.loginCallback);
}