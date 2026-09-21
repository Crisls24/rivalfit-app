import 'deep_link.dart';

/// Host verificado por Android App Links (assetlinks.json servido por Envoy).
const String kAppLinkHost = 'fit-api.iscx.site';

/// Custom scheme de la app. SOLO como compatibilidad interna (login-callback
/// de PKCE y reset desde el correo); nunca se comparte con otras personas.
const String kAppCustomScheme = 'com.rivalfit.rivalfit';

/// Codigo de invitacion: 6 caracteres alfanumericos. La BD genera los codigos
/// sin I/O/0/1, pero el parser acepta cualquier letra/digito; la validacion
/// final la hace la liga al resolver el codigo (si la liga no existe, la
/// landing responde "invitacion no disponible").
final RegExp _joinCodePattern = RegExp(r'^[A-Z0-9]{6}$');

/// Invitacion de liga lista para compartir: un enlace https verificado por
/// App Links. El custom scheme `com.rivalfit.rivalfit://join/CODE` queda
/// fuera de lo que recibe un amigo.
String joinInviteLink(String code) =>
    'https://$kAppLinkHost/join/${code.trim().toUpperCase()}';

/// Convierte un URI profundo (https de App Links o custom scheme) en una
/// [DeepLinkAction] que el router pueda atender.
///
/// Flujo soportado:
///
/// ```
/// URI
///  ↓
/// DeepLinkParser
///  ↓
/// DeepLinkAction.join(code)
///  ↓
/// router.go('/join/:code')
/// ```
class DeepLinkParser {
  const DeepLinkParser();

  /// Devuelve null si el URI no representa una accion de la app.
  DeepLinkAction? parse(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments;

    // Invitacion a liga:
    //   https://fit-api.iscx.site/join/CODE        (canonico, App Links)
    //   com.rivalfit.rivalfit://join/CODE          (compatibilidad interna)
    final isCustom = scheme == kAppCustomScheme;
    final isVerifiedHttps = scheme == 'https' && host == kAppLinkHost;
    if (host == 'join' ||
        (segments.isNotEmpty && segments.first == 'join')) {
      if (isCustom || isVerifiedHttps) {
        final code = _joinCodeAt(host, segments);
        if (code != null) return DeepLinkAction.join(code);
      }
    }

    // Callback OAuth: lo consume supabase_flutter (PKCE), aqui no es accion.
    if (isCustom && host == 'login-callback') {
      return const DeepLinkAction.loginCallback();
    }

    // Recuperacion de contrasena:
    //   com.rivalfit.rivalfit://reset?email=..&code=..
    //   https://fit-api.iscx.site/reset?email=..&code=..
    final query = uri.queryParameters;
    final isReset = host == 'reset' ||
        uri.path.contains('reset') ||
        query.containsKey('code');
    if (!isReset) return null;

    final rawEmail = query['email'];
    if (rawEmail == null || rawEmail.isEmpty) return null;
    final digits =
        (query['code'] ?? query['token'] ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    // El '+' del correo se decodifica como espacio en el query string.
    return DeepLinkAction.reset(
      email: rawEmail.replaceAll(' ', '+'),
      recoveryCode: digits,
    );
  }

  /// Extrae el codigo segun la forma del URI: custom scheme (host=join) o
  /// https verificado (/join/CODE).
  String? _joinCodeAt(String host, List<String> segments) {
    final raw = host == 'join' ? (segments.isNotEmpty ? segments.first : '') : null;
    String? candidate;
    if (raw != null) {
      candidate = raw;
    } else if (segments.length > 1) {
      candidate = segments[1];
    }
    if (candidate == null) return null;
    final code = candidate.trim().toUpperCase();
    return _joinCodePattern.hasMatch(code) ? code : null;
  }
}