import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/home/presentation/widgets/daily_steps_card.dart';

void main() {
  const channel = MethodChannel('rivalfit/daily_steps');
  const control = MethodChannel('rivalfit/cardio');
  const events = MethodChannel('rivalfit/cardio_steps');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(control, (_) async => 'denied');
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final methodChannel in [channel, control, events]) {
      messenger.setMockMethodCallHandler(methodChannel, null);
    }
  });

  Future<void> showCard(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(
          body: SingleChildScrollView(child: DailyStepsCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> hideCard(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
    debugDefaultTargetPlatformOverride = null;
  }

  testWidgets('requests access after a tap and rereads steps on resume', (
    tester,
  ) async {
    final calls = <String>[];
    var allowed = false;
    var count = 432;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      if (call.method == 'requestAccess') {
        allowed = true;
        return {'status': 'granted'};
      }
      return allowed
          ? {'status': 'ready', 'steps': count}
          : {'status': 'permission'};
    });

    await showCard(tester);
    expect(calls, ['today']);
    expect(find.text('Conectar pasos'), findsOneWidget);
    await tester.tap(find.text('Conectar pasos'));
    await tester.pumpAndSettle();
    expect(find.text('432'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    count = 768;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('768'), findsOneWidget);
    expect(calls, ['today', 'requestAccess', 'today', 'today']);
    await hideCard(tester);
  });

  testWidgets('shows the missing data source instead of a zero total', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => {'status': 'needsSource', 'steps': 0},
    );
    await showCard(tester);
    expect(find.text('Abrir Health Connect'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    await hideCard(tester);
  });

  testWidgets(
    'updates one total automatically and reconciles Health Connect batches',
    (tester) async {
      final messenger = tester.binding.defaultBinaryMessenger;
      final streamCalls = <String>[];
      final controlCalls = <String>[];
      var count = 432;
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {'status': 'ready', 'steps': count},
      );
      messenger.setMockMethodCallHandler(control, (call) async {
        controlCalls.add(call.method);
        return 'ready';
      });
      messenger.setMockMethodCallHandler(events, (call) async {
        streamCalls.add(call.method);
        return null;
      });

      await showCard(tester);
      expect(find.text('432'), findsOneWidget);
      expect(find.text('Ver en vivo'), findsNothing);
      expect(find.byTooltip('Actualizar pasos'), findsNothing);
      expect(streamCalls, ['listen']);
      Future<void> emitSteps([int count = 1]) async {
        await messenger.handlePlatformMessage(
          events.name,
          const StandardMethodCodec().encodeSuccessEnvelope(count),
          (_) {},
        );
        await tester.pump();
      }

      await emitSteps(3);
      expect(find.text('435'), findsOneWidget);
      count = 435;
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
      expect(find.text('435'), findsOneWidget);
      await emitSteps();
      expect(find.text('436'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(streamCalls, ['listen', 'cancel']);
      count = 440;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('440'), findsOneWidget);
      await tester.pump();
      expect(streamCalls, ['listen', 'cancel', 'listen']);
      expect(controlCalls, ['prepareDaily', 'prepareDaily']);
      await emitSteps();
      expect(find.text('441'), findsOneWidget);
      await hideCard(tester);
    },
  );
}
