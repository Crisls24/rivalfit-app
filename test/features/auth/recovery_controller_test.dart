import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rivalfit/core/error/failures.dart';
import 'package:rivalfit/features/auth/domain/repositories/auth_repository.dart';
import 'package:rivalfit/features/auth/presentation/controllers/recovery_controller.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late RecoveryController controller;

  setUp(() {
    repo = MockAuthRepository();
    controller = RecoveryController(repo);
  });

  tearDown(() {
    controller.dispose();
  });

  group('maskEmail', () {
    test('mantiene la primera letra y el dominio', () {
      expect(maskEmail('crfewr@gmail.com'), 'c***@gmail.com');
    });

    test('local corto usa menos asteriscos', () {
      expect(maskEmail('ab@gmail.com'), 'a**@gmail.com');
    });

    test('sin arroba devuelve el mismo texto', () {
      expect(maskEmail('hola'), 'hola');
    });
  });

  group('requestCode', () {
    test('con email valido avanza a otp, enmascara y arranca cooldown', () async {
      when(() => repo.sendRecoveryCode(any()))
          .thenAnswer((_) async => null);

      await controller.requestCode(' crfewr@gmail.com ');

      expect(controller.state.step, RecoveryStep.otp);
      expect(controller.state.email, 'crfewr@gmail.com');
      expect(controller.state.maskedEmail, 'c***@gmail.com');
      expect(controller.state.cooldownSeconds, recoveryResendCooldown);
      expect(controller.state.errorMessage, isNull);
      verify(() => repo.sendRecoveryCode('crfewr@gmail.com')).called(1);
    });

    test('email invalido no llama al repo y muestra error', () async {
      await controller.requestCode('no-es-correo');

      expect(controller.state.step, RecoveryStep.email);
      expect(controller.state.errorMessage, 'Ingresa un correo válido');
      verifyNever(() => repo.sendRecoveryCode(any()));
    });

    test('error del repo se refleja sin avanzar de paso', () async {
      when(() => repo.sendRecoveryCode(any())).thenAnswer(
        (_) async => AuthFailure(
          message: 'Demasiadas solicitudes. Espera un momento e inténtalo de nuevo.',
        ),
      );

      await controller.requestCode('crfewr@gmail.com');

      expect(controller.state.step, RecoveryStep.email);
      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.errorMessage, contains('Demasiadas solicitudes'));
    });
  });

  group('verifyCode', () {
    Future<void> goToOtp() async {
      when(() => repo.sendRecoveryCode(any()))
          .thenAnswer((_) async => null);
      await controller.requestCode('crfewr@gmail.com');
    }

    test('codigo correcto pasa a nueva contrasena', () async {
      await goToOtp();
      when(() => repo.verifyRecoveryCode(
        email: any(named: 'email'),
        code: any(named: 'code'),
      )).thenAnswer((_) async => null);

      await controller.verifyCode('123456');

      expect(controller.state.step, RecoveryStep.password);
      verify(() => repo.verifyRecoveryCode(
        email: 'crfewr@gmail.com',
        code: '123456',
      )).called(1);
    });

    test('codigo incorrecto muestra mensaje y se queda en otp', () async {
      await goToOtp();
      when(() => repo.verifyRecoveryCode(
        email: any(named: 'email'),
        code: any(named: 'code'),
      )).thenAnswer(
        (_) async => AuthFailure(
          message: 'Código incorrecto o expirado. Solicita uno nuevo.',
        ),
      );

      await controller.verifyCode('000000');

      expect(controller.state.step, RecoveryStep.otp);
      expect(controller.state.errorMessage, contains('incorrecto o expirado'));
    });
  });

  group('resendCode', () {
    test('ignora mientras el cooldown esta activo', () async {
      when(() => repo.sendRecoveryCode(any()))
          .thenAnswer((_) async => null);

      await controller.requestCode('crfewr@gmail.com');
      await controller.resendCode();

      verify(() => repo.sendRecoveryCode('crfewr@gmail.com')).called(1);
    });
  });

  group('changePassword', () {
    test('actualiza la clave y marca exito', () async {
      when(() => repo.resetPassword(any()))
          .thenAnswer((_) async => null);

      await controller.changePassword('NuevaClave1!');

      expect(controller.state.step, RecoveryStep.success);
      expect(controller.state.justCompleted, isTrue);
      verify(() => repo.resetPassword('NuevaClave1!')).called(1);
    });

    test('reset devuelve al inicio y deja de marcar exito', () async {
      when(() => repo.resetPassword(any()))
          .thenAnswer((_) async => null);

      await controller.changePassword('NuevaClave1!');
      controller.reset();

      expect(controller.state.step, RecoveryStep.email);
      expect(controller.state.justCompleted, isFalse);
      expect(controller.state.cooldownSeconds, 0);
    });
  });

  group('back', () {
    test('vuelve de otp a email', () async {
      when(() => repo.sendRecoveryCode(any()))
          .thenAnswer((_) async => null);
      await controller.requestCode('crfewr@gmail.com');

      controller.back();

      expect(controller.state.step, RecoveryStep.email);
    });
  });
}