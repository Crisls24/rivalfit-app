import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/exercise/domain/models/posture_readiness.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';
import 'package:rivalfit/features/exercise/domain/services/core_counter.dart';

void main() {
  CoreObservation crunch(int ms, double tilt, {int side = 0}) =>
      CoreObservation(
        timestamp: Duration(milliseconds: ms),
        readiness: const PostureReadiness(true, true, ''),
        side: side,
        aligned: true,
        torsoTilt: tilt,
        torsoLength: .2,
        hipHeight: .6,
        kneeAngle: 78,
      );

  test('crunch counts a complete lift and return once', () {
    final counter = CoreCounter(plank: false)..arm(crunch(0, 4));
    expect(counter.observe(crunch(200, 17)), isFalse);
    expect(counter.observe(crunch(500, 29)), isFalse);
    expect(counter.observe(crunch(740, 5)), isTrue);
    expect(counter.observe(crunch(900, 4)), isFalse);
  });

  test('a partial lift or camera-side change cannot complete a crunch', () {
    final counter = CoreCounter(plank: false)..arm(crunch(0, 4));
    expect(counter.observe(crunch(300, 18)), isFalse);
    expect(counter.observe(crunch(900, 4)), isFalse);
    expect(counter.observe(crunch(1150, 30)), isFalse);
    expect(counter.observe(crunch(1750, 5, side: 1)), isFalse);
  });

  test('plank requires aligned legs and an elbow under the shoulder', () {
    final gate = CorePoseGate();
    CoreObservation pose(int ms, {double hip = .54, double elbowX = .26}) =>
        gate.evaluate(
          left: [
            const BodyPoint(.25, .48, .99),
            BodyPoint(.46, hip, .99),
            const BodyPoint(.63, .59, .99),
            const BodyPoint(.79, .64, .99),
            BodyPoint(elbowX, .64, .99),
          ],
          right: const [],
          timestamp: Duration(milliseconds: ms),
          aspectRatio: 1,
          plank: true,
        );
    expect(pose(0).readiness.initialPostureReady, isFalse);
    expect(pose(550).readiness.initialPostureReady, isTrue);
    expect(pose(700, hip: .40).aligned, isFalse);
    expect(pose(800).readiness.initialPostureReady, isFalse);
    final misplacedElbow = pose(900, elbowX: .6);
    expect(misplacedElbow.aligned, isFalse);
    expect(
      misplacedElbow.readiness.instruction,
      'Coloca los codos debajo de los hombros.',
    );
  });

  test('personal results retain their units without league eligibility', () {
    TrainingSessionResult roundTrip(
      String exercise,
      TrainingSource source, {
      int reps = 0,
      int steps = 0,
      Duration hold = Duration.zero,
    }) {
      final result = TrainingSessionResult(
        sessionId: 'personal-session',
        exerciseId: exercise,
        rulesVersion: '$exercise-v1',
        source: source,
        startedAtUtc: DateTime.utc(2026),
        endedAtUtc: DateTime.utc(2026, 1, 1, 0, 0, 8),
        activeDuration: const Duration(seconds: 8),
        validReps: reps,
        steps: steps,
        holdDuration: hold,
      );
      return TrainingSessionResult.fromJson(result.toJson());
    }

    final plank = roundTrip(
      'plancha',
      TrainingSource.camera,
      hold: const Duration(seconds: 5),
    );
    final cardio = roundTrip('cardio', TrainingSource.stepSensor, steps: 12);
    final abdominal = roundTrip('abdominales', TrainingSource.camera, reps: 1);
    expect(plank.measurementLabel, '5 s');
    expect(cardio.measurementLabel, '12 pasos');
    expect(abdominal.measurementLabel, '1 repetición');
    for (final result in [plank, cardio, abdominal]) {
      expect(result.eligibleForLocalHistory, isTrue);
      expect(result.eligibleForSubmission, isFalse);
    }
  });
}
