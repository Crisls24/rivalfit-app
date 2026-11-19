import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/exercise/domain/models/posture_readiness.dart';

void main() {
  const left = [
    BodyPoint(.4, .4, .9),
    BodyPoint(.4, .6, .9),
    BodyPoint(.4, .85, .9),
  ];
  const right = [
    BodyPoint(.6, .4, .9),
    BodyPoint(.6, .6, .9),
    BodyPoint(.6, .85, .9),
  ];
  const shoulders = [BodyPoint(.4, .2, .9), BodyPoint(.6, .2, .9)];

  test(
    'requires a stable initial posture and resets when joints disappear',
    () {
      final gate = PostureReadinessGate();
      PostureReadiness evaluate(int ms, {List<BodyPoint> leg = left}) =>
          gate.evaluate(
            leftLeg: leg,
            rightLeg: right,
            shoulders: shoulders,
            timestamp: Duration(milliseconds: ms),
          );
      expect(evaluate(0).initialPostureReady, isFalse);
      expect(evaluate(699).initialPostureReady, isFalse);
      expect(evaluate(700).initialPostureReady, isTrue);
      expect(evaluate(800, leg: []).bodyVisible, isFalse);
      expect(evaluate(900).initialPostureReady, isFalse);
      expect(evaluate(1600).initialPostureReady, isTrue);
    },
  );

  test('low confidence and joints outside the frame prevent preparation', () {
    final gate = PostureReadinessGate();
    final result = gate.evaluate(
      leftLeg: const [
        BodyPoint(.4, .4, .3),
        BodyPoint(.4, .6, .9),
        BodyPoint(.4, 1.1, .9),
      ],
      rightLeg: right,
      shoulders: shoulders,
      timestamp: Duration.zero,
    );
    expect(result.bodyVisible, isFalse);
    expect(result.initialPostureReady, isFalse);
  });

  test(
    'a bent knee can remain visible without qualifying as initial posture',
    () {
      final gate = PostureReadinessGate();
      final result = gate.evaluate(
        leftLeg: const [
          BodyPoint(.4, .4, .9),
          BodyPoint(.6, .6, .9),
          BodyPoint(.4, .85, .9),
        ],
        rightLeg: right,
        shoulders: shoulders,
        timestamp: const Duration(seconds: 2),
      );
      expect(result.bodyVisible, isTrue);
      expect(result.initialPostureReady, isFalse);
    },
  );
}
