import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el instante del ultimo lanzamiento de OAuth para impedir que el
/// navegador se abra dos veces seguidas (doble tap o recreacion de la app
/// mientras ya hay un OAuth en curso).
class RouteKeeper {
  static const _lastLaunchKey = 'oauth_last_launch_at';

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
}