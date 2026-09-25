import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/app/router.dart';

void main() {
  group('initialRouteFor', () {
    test('login-callback (arranque en frio por OAuth) arranca en /login', () {
      expect(
        initialRouteFor(
          Uri.parse('com.rivalfit.rivalfit://login-callback?code=abc'),
          oauthPending: false,
        ),
        '/login',
      );
    });

    test('OAuth pendiente aunque no haya enlace inicial arranca en /login', () {
      expect(initialRouteFor(null, oauthPending: true), '/login');
    });

    test('OAuth pendiente + enlace normal tambien arranca en /login', () {
      expect(
        initialRouteFor(
          Uri.parse('https://fit-api.iscx.site/join/ABC123'),
          oauthPending: true,
        ),
        '/login',
      );
    });

    test('sin enlace inicial y sin OAuth pendiente arranca en /onboarding', () {
      expect(initialRouteFor(null, oauthPending: false), '/onboarding');
    });

    test('un enlace que no es accion arranca en /onboarding', () {
      expect(
        initialRouteFor(Uri.parse('https://example.com/foo'), oauthPending: false),
        '/onboarding',
      );
    });

    test('invitacion de liga no altera la ruta inicial', () {
      expect(
        initialRouteFor(
          Uri.parse('https://fit-api.iscx.site/join/ABC123'),
          oauthPending: false,
        ),
        '/onboarding',
      );
    });

    test('recuperacion de contrasena no altera la ruta inicial', () {
      expect(
        initialRouteFor(
          Uri.parse('com.rivalfit.rivalfit://reset?email=a%40b.com&code=123456'),
          oauthPending: false,
        ),
        '/onboarding',
      );
    });
  });
}