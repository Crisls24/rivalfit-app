import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el instante del ultimo lanzamiento de OAuth para impedir que el
/// navegador se abra dos veces seguidas (doble tap o recreacion de la app
/// mientras ya hay un OAuth en curso). Tambien marca cuando hay un OAuth
/// pendiente de resolver para que un arranque en frio "regrese al login"
/// (y no al onboarding) mientras supabase termina de confirmar la sesion.
class RouteKeeper {
  static const _lastLaunchKey = 'oauth_last_launch_at';
  static const _pendingKey = 'oauth_pending';

  /// Ventana para impedir lanzar el navegador dos veces seguidas.
  static const _launchCooldown = Duration(seconds: 5);

  /// Permite lanzar un OAuth solo si no hubo otro en los ultimos
  /// [_launchCooldown]. Registra el instante del lanzamiento.
  static Future<bool> allowOAuthLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastLaunchKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < _launchCooldown.inMilliseconds) return false;
    await prefs.setInt(_lastLaunchKey, now);
    return true;
  }

  /// Marca que hay un OAuth en vuelo (el navegador esta abierto esperando el
  /// deep link). Un arranque en frio mientras esto este marcado debe arrancar
  /// en /login, nunca en onboarding.
  static Future<void> markOAuthPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingKey, true);
  }

  /// Limpia el marcador cuando el OAuth se resolvio (sesion obtenida o
  /// cancelado/fallo).
  static Future<void> clearOAuthPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }

  /// True si en algun momento se lanzo un OAuth y este aun no se resolvio.
  static Future<bool> isOAuthPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingKey) ?? false;
  }
}