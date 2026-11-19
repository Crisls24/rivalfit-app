import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/exercise/domain/models/posture_readiness.dart';
import 'package:rivalfit/features/exercise/domain/models/squat_observation.dart';
import 'package:rivalfit/features/exercise/domain/services/squat_counter.dart';

SquatObservation sample(
  int ms,
  double angle, {
  bool visible = true,
  double? rightAngle,
  double? hipHeight,
}) => SquatObservation(
  timestamp: Duration(milliseconds: ms),
  readiness: PostureReadiness(visible, visible && angle >= 160, ''),
  leftKneeAngle: angle,
  rightKneeAngle: rightAngle ?? angle,
  hipHeight: hipHeight ?? (angle <= 105 ? 0.33 : 0.50),
);

void main() {
  test('one complete cycle counts once; remaining upright does not count', () {
    final counter = SquatCounter();
    var reps = 0;
    for (final point in [
      [0, 170],
      [300, 170],
      [450, 135],
      [600, 100],
      [800, 100],
      [1000, 170],
      [1300, 170],
      [1600, 170],
    ]) {
      if (counter.observe(sample(point[0], point[1].toDouble()))) reps++;
    }
    expect(reps, 1);
  });

  test('partial descents and a single noisy depth sample do not count', () {
    for (final angles in [
      [
        [0, 170],
        [300, 170],
        [450, 135],
        [600, 170],
        [900, 170],
      ],
      [
        [0, 170],
        [300, 170],
        [450, 100],
        [600, 135],
        [800, 170],
        [1100, 170],
      ],
    ]) {
      final counter = SquatCounter();
      expect(
        angles.any((p) => counter.observe(sample(p[0], p[1].toDouble()))),
        isFalse,
      );
    }
  });

  test('deep knee angles without a sustained hip drop do not count', () {
    final counter = SquatCounter()..arm(sample(0, 170));
    counter.observe(sample(150, 135, hipHeight: 0.47));
    counter.observe(sample(300, 100, hipHeight: 0.46));
    counter.observe(sample(500, 100, hipHeight: 0.45));
    expect(counter.phase, SquatPhase.descending);
    expect(counter.observe(sample(700, 170)), isFalse);
    expect(counter.observe(sample(1000, 170)), isFalse);
    expect(counter.instruction, 'En la siguiente, baja un poco más.');
  });

  test('a repetition needs both legs and hips to return to the start', () {
    final counter = SquatCounter()..arm(sample(0, 170));
    counter.observe(sample(150, 135));
    counter.observe(sample(300, 100));
    counter.observe(sample(500, 100));
    expect(counter.phase, SquatPhase.depthReached);
    expect(counter.observe(sample(650, 170, hipHeight: 0.38)), isFalse);
    expect(counter.observe(sample(950, 170, hipHeight: 0.38)), isFalse);
    expect(counter.observe(sample(1100, 170)), isFalse);
    expect(counter.observe(sample(1400, 170)), isTrue);
    expect(counter.observe(sample(1700, 170)), isFalse);
  });

  test('hip drop is relative to each initial standing height', () {
    final counter = SquatCounter()..arm(sample(0, 170, hipHeight: 0.30));
    counter.observe(sample(150, 135, hipHeight: 0.27));
    counter.observe(sample(300, 100, hipHeight: 0.21));
    counter.observe(sample(500, 100, hipHeight: 0.21));
    expect(counter.observe(sample(650, 170, hipHeight: 0.30)), isFalse);
    expect(counter.observe(sample(950, 170, hipHeight: 0.30)), isTrue);
  });

  test(
    'visibility loss, reset and long frame gaps discard a partial cycle',
    () {
      for (final interruption in ['loss', 'reset', 'gap']) {
        final counter = SquatCounter();
        for (final p in [
          [0, 170],
          [300, 170],
          [450, 100],
          [650, 100],
        ]) {
          counter.observe(sample(p[0], p[1].toDouble()));
        }
        if (interruption == 'loss') {
          counter.observe(sample(750, 100, visible: false));
        }
        if (interruption == 'reset') counter.reset();
        final start = interruption == 'gap' ? 1500 : 900;
        expect(counter.observe(sample(start, 170)), isFalse);
        expect(counter.observe(sample(start + 300, 170)), isFalse);
      }
    },
  );

  test('duplicate frames cannot satisfy stability thresholds', () {
    final counter = SquatCounter();
    counter.observe(sample(0, 170));
    for (var i = 0; i < 20; i++) {
      expect(counter.observe(sample(0, 170)), isFalse);
    }
    expect(counter.phase, SquatPhase.waitingForStart);
  });

  test('invalid or inconsistent angles reset the cycle', () {
    for (final angle in [double.nan, double.infinity, -1.0, 200.0]) {
      final counter = SquatCounter();
      counter.observe(sample(0, 170));
      counter.observe(sample(300, 170));
      expect(counter.observe(sample(450, angle)), isFalse);
      expect(counter.phase, SquatPhase.waitingForStart);
    }
    final counter = SquatCounter();
    counter.observe(sample(0, 170));
    counter.observe(sample(300, 170));
    expect(counter.observe(sample(450, 100, rightAngle: 170)), isFalse);
    expect(counter.phase, SquatPhase.waitingForStart);
  });
}
