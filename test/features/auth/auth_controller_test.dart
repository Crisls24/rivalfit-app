import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rivalfit/features/auth/domain/entities/user.dart';
import 'package:rivalfit/features/auth/domain/repositories/auth_repository.dart';
import 'package:rivalfit/features/auth/presentation/controllers/auth_controller.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthState.copyWith errorMessage', () {
    test('null explicito limpia el error (regresion: bucle de ref.listen)',
        () {
      const state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Este correo ya está registrado. Inicia sesión.',
      );

      final cleared = state.copyWith(errorMessage: null);

      expect(cleared.errorMessage, isNull);
    });

    test('omitir el parametro conserva el error previo', () {
      const state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'boom',
      );

      final next = state.copyWith(status: AuthStatus.loading);

      expect(next.errorMessage, 'boom');
    });
  });

  group('AuthController.clearError', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
      when(() => repo.onAuthStateChange)
          .thenAnswer((_) => const Stream<User?>.empty());
      when(() => repo.getCurrentUser())
          .thenAnswer((_) async => (user: null, error: null));
    });

    test('deja errorMessage en null para que el listener no se re-dispare',
        () async {
      final controller = AuthController(repo);
      await Future<void>.delayed(Duration.zero);

      controller.state = controller.state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Este correo ya está registrado. Inicia sesión.',
      );
      expect(controller.state.errorMessage, isNotNull);

      controller.clearError();

      expect(controller.state.errorMessage, isNull);
      expect(controller.state.status, AuthStatus.error);

      controller.dispose();
    });
  });
}
