import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/core/deeplinks/deep_link.dart';
import 'package:rivalfit/core/deeplinks/deep_link_parser.dart';

void main() {
  const parser = DeepLinkParser();

  group('joinInviteLink', () {
    test('construye el enlace https canonico con el codigo en mayusculas', () {
      expect(
        joinInviteLink('abc123'),
        'https://fit-api.iscx.site/join/ABC123',
      );
    });
  });

  group('invitacion https valida', () {
    test('resuelve el codigo', () {
      final action = parser.parse(Uri.parse('https://fit-api.iscx.site/join/ABC123'));
      expect(action?.kind, DeepLinkKind.join);
      expect(action?.joinCode, 'ABC123');
    });

    test('normaliza el codigo a mayusculas', () {
      final action = parser.parse(Uri.parse('https://fit-api.iscx.site/join/abc123'));
      expect(action?.joinCode, 'ABC123');
    });

    test('ignora query parameters (source=whatsapp)', () {
      final action = parser
          .parse(Uri.parse('https://fit-api.iscx.site/join/ABC123?source=whatsapp'));
      expect(action?.joinCode, 'ABC123');
    });
  });

  group('invitacion por custom scheme (compatibilidad interna)', () {
    test('resuelve el codigo igual que el enlace https', () {
      final action =
          parser.parse(Uri.parse('com.rivalfit.rivalfit://join/ABC123'));
      expect(action?.kind, DeepLinkKind.join);
      expect(action?.joinCode, 'ABC123');
    });
  });

  group('rutas invalidas', () {
    test('otra ruta del host no es una invitacion', () {
      final action = parser
          .parse(Uri.parse('https://fit-api.iscx.site/profile/ABC123'));
      expect(action, isNull);
    });

    test('codigo vacio no es valido', () {
      final action = parser.parse(Uri.parse('https://fit-api.iscx.site/join/'));
      expect(action, isNull);
    });

    test('codigo demasiado corto no es valido', () {
      final action =
          parser.parse(Uri.parse('https://fit-api.iscx.site/join/AB12'));
      expect(action, isNull);
    });

    test('host ajeno no se atiende aunque la ruta parezca una invitacion', () {
      final action = parser.parse(Uri.parse('https://example.com/join/ABC123'));
      expect(action, isNull);
    });
  });

  group('recuperacion de contrasena', () {
    test('custom scheme con email y codigo', () {
      final action = parser.parse(
        Uri.parse(
          'com.rivalfit.rivalfit://reset?email=test%40gmail.com&code=123456',
        ),
      );
      expect(action?.kind, DeepLinkKind.reset);
      expect(action?.email, 'test@gmail.com');
      expect(action?.recoveryCode, '123456');
    });

    test('https verificado con email y codigo', () {
      final action = parser.parse(
        Uri.parse('https://fit-api.iscx.site/reset?email=test%40gmail.com&code=123456'),
      );
      expect(action?.kind, DeepLinkKind.reset);
      expect(action?.email, 'test@gmail.com');
      expect(action?.recoveryCode, '123456');
    });

    test('el + del correo se restaura al decodificar', () {
      final action = parser.parse(
        Uri.parse(
          'com.rivalfit.rivalfit://reset?email=test%2Bmaestra%40gmail.com&code=123456',
        ),
      );
      expect(action?.kind, DeepLinkKind.reset);
      expect(action?.email, 'test+maestra@gmail.com');
    });

    test('sin email no es recuperacion', () {
      final action = parser
          .parse(Uri.parse('com.rivalfit.rivalfit://reset?code=123456'));
      expect(action, isNull);
    });
  });

  group('login callback (PKCE)', () {
    test('es una accion de tipo loginCallback, no una invitacion', () {
      final action = parser.parse(
        Uri.parse('com.rivalfit.rivalfit://login-callback?code=abc'),
      );
      expect(action?.kind, DeepLinkKind.loginCallback);
      expect(action?.joinCode, isNull);
    });
  });
}