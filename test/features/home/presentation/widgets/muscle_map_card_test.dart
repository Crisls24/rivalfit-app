import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/home/presentation/widgets/muscle_map_card.dart';

void main() {
  testWidgets('body taps and chips update the same zone on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: MuscleMapCard())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 reps confirmadas'), findsOneWidget);
    expect(find.text('Sin entrenar'), findsOneWidget);
    expect(find.text('1 rep para Bronce'), findsOneWidget);
    final body = tester.getRect(find.byType(Image));
    await tester.tapAt(
      body.topLeft + Offset(body.width * 0.5, body.height * 0.34),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Abdomen'))
          .selected,
      isTrue,
    );
    expect(find.text('Abdomen'), findsNWidgets(2));
    expect(find.text('Sin entrenar'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Piernas'));
    await tester.pumpAndSettle();
    expect(find.text('Piernas'), findsNWidgets(2));
    expect(find.byType(OutlinedButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the first confirmed leg rep unlocks Bronze only for legs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: MuscleMapCard(legReps: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 reps confirmadas'), findsOneWidget);
    expect(find.text('Bronce'), findsOneWidget);
    expect(find.text('Bronce alcanzado'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Abdomen'));
    await tester.pumpAndSettle();

    expect(find.text('0 reps confirmadas'), findsOneWidget);
    expect(find.text('Sin entrenar'), findsOneWidget);
    expect(find.text('Bronce'), findsNothing);
  });
}
