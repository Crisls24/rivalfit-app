import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/auth/presentation/widgets/otp_code_input.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('al completar los 6 digitos hace onCompleted', (tester) async {
    final completed = <String>[];
    await tester.pumpWidget(_wrap(OtpCodeInput(onCompleted: completed.add)));

    for (var i = 0; i < 6; i++) {
      await tester.enterText(find.byType(TextField).at(i), '${i + 1}');
      await tester.pump();
    }

    expect(completed, ['123456']);
  });

  testWidgets('el paste de varios digitos se reparte y completa', (tester) async {
    final completed = <String>[];
    await tester.pumpWidget(_wrap(OtpCodeInput(onCompleted: completed.add)));

    await tester.enterText(find.byType(TextField).at(0), '987654');
    await tester.pump();

    expect(completed, ['987654']);
  });

  testWidgets('errorText limpia las cajas', (tester) async {
    await tester.pumpWidget(_wrap(OtpCodeInput()));
    await tester.enterText(find.byType(TextField).at(0), '1');
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      '1',
    );

    await tester.pumpWidget(_wrap(OtpCodeInput(errorText: 'Código incorrecto')));
    await tester.pump(const Duration(milliseconds: 500));

    for (var i = 0; i < 6; i++) {
      expect(
        tester.widget<TextField>(find.byType(TextField).at(i)).controller!.text,
        isEmpty,
        reason: 'la caja $i debio limpiarse tras el error',
      );
    }
  });

  testWidgets('readOnly mientras isVerifying bloquea la entrada', (tester) async {
    await tester.pumpWidget(_wrap(OtpCodeInput(isVerifying: true)));
    await tester.enterText(find.byType(TextField).at(0), '1');
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      isEmpty,
    );
  });
}