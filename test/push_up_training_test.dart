import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/exercise/domain/models/posture_readiness.dart';
import 'package:rivalfit/features/exercise/domain/models/saved_training_session.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';
import 'package:rivalfit/features/exercise/domain/services/push_up_counter.dart';
import 'package:rivalfit/features/exercise/presentation/controllers/training_session_controller.dart';
import 'package:rivalfit/features/home/presentation/training_progress.dart';

PushUpObservation frame(
  int ms,
  double angle,
  double height, {
  bool visible = true,
  bool aligned = true,
  PushUpSide side = PushUpSide.left,
}) => PushUpObservation(
  timestamp: Duration(milliseconds: ms),
  readiness: PostureReadiness(visible, visible && aligned && angle >= 155, ''),
  elbowAngle: angle,
  shoulderHeight: height,
  side: visible ? side : null,
  aligned: aligned,
);

void main() {
  test('a side-on plank needs stable landmarks and arm extension to start', () {
    final gate = PushUpPoseGate();
    const points = [
      BodyPoint(.25, .50, .9),
      BodyPoint(.25, .60, .9),
      BodyPoint(.25, .70, .9),
      BodyPoint(.50, .55, .9),
      BodyPoint(.76, .60, .9),
    ];
    PushUpObservation observe(
      int ms,
      List<BodyPoint> left,
      List<BodyPoint> right,
    ) => gate.evaluate(
      left: left,
      right: right,
      timestamp: Duration(milliseconds: ms),
      aspectRatio: .65,
    );

    expect(observe(0, points, []).readiness.initialPostureReady, isFalse);
    expect(observe(700, points, points).readiness.initialPostureReady, isTrue);
    expect(observe(850, [], points).readiness.initialPostureReady, isFalse);
    expect(observe(1550, [], points).readiness.initialPostureReady, isTrue);
    final bent = [...points]..[1] = const BodyPoint(.4, .6, .9);
    expect(observe(1700, [], bent).readiness.initialPostureReady, isFalse);
    final vertical = [...points]..[4] = const BodyPoint(.25, .81, .9);
    expect(observe(1850, [], vertical).aligned, isFalse);
  });

  test('diagonal camera landmarks can start and count a complete rep', () {
    final gate = PushUpPoseGate();
    const points = [
      BodyPoint(.40, .47, .9),
      BodyPoint(.40, .56, .9),
      BodyPoint(.40, .65, .9),
      BodyPoint(.46, .50, .9),
      BodyPoint(.53, .535, .9),
    ];
    const lowered = [
      BodyPoint(.395, .56, .9),
      BodyPoint(.50, .57, .9),
      BodyPoint(.40, .65, .9),
      BodyPoint(.46, .548, .9),
      BodyPoint(.53, .535, .9),
    ];
    PushUpObservation observe(int ms, [List<BodyPoint> pose = points]) =>
        gate.evaluate(
          left: pose,
          right: [],
          timestamp: Duration(milliseconds: ms),
          aspectRatio: .65,
        );

    expect(observe(0).aligned, isTrue);
    final ready = observe(700);
    expect(ready.readiness.initialPostureReady, isTrue);
    final counter = PushUpCounter()..arm(ready);
    expect(counter.observe(observe(850, lowered)), isFalse);
    expect(counter.observe(observe(1050, lowered)), isFalse);
    expect(counter.phase, PushUpPhase.bottom);
    expect(counter.observe(observe(1200)), isFalse);
    expect(counter.observe(observe(1500)), isTrue);
  });

  test('a full push-up counts once and holding the top does not repeat it', () {
    final counter = PushUpCounter()..arm(frame(0, 170, .5));
    expect(counter.observe(frame(150, 135, .43)), isFalse);
    expect(counter.observe(frame(300, 90, .32)), isFalse);
    expect(counter.observe(frame(500, 90, .32)), isFalse);
    expect(counter.observe(frame(700, 170, .5)), isFalse);
    expect(counter.observe(frame(1000, 170, .5)), isTrue);
    expect(counter.observe(frame(1300, 170, .5)), isFalse);
  });

  test('a shallow descent and isolated elbow bend do not count', () {
    for (final bottom in [frame(300, 110, .32), frame(300, 90, .46)]) {
      final counter = PushUpCounter()..arm(frame(0, 170, .5));
      expect(counter.observe(frame(150, 135, .43)), isFalse);
      expect(counter.observe(bottom), isFalse);
      expect(counter.observe(frame(500, 110, .40)), isFalse);
      expect(counter.observe(frame(700, 170, .5)), isFalse);
      expect(counter.observe(frame(1000, 170, .5)), isFalse);
      expect(counter.phase, PushUpPhase.extended);
    }
  });

  test(
    'visibility loss, bad alignment and side switches discard a partial',
    () {
      for (final interruption in [
        frame(650, 90, .32, visible: false),
        frame(650, 90, .32, aligned: false),
        frame(650, 90, .32, side: PushUpSide.right),
      ]) {
        final counter = PushUpCounter()..arm(frame(0, 170, .5));
        counter.observe(frame(150, 135, .43));
        counter.observe(frame(300, 90, .32));
        counter.observe(frame(500, 90, .32));
        expect(counter.phase, PushUpPhase.bottom);
        expect(counter.observe(interruption), isFalse);
        expect(counter.observe(frame(800, 170, .5)), isFalse);
        expect(counter.observe(frame(1100, 170, .5)), isFalse);
      }
    },
  );

  test('a visible alignment error invalidates the current push-up', () {
    final session = TrainingSessionController(
      movement: TrainingMovement.pushUp,
    );
    addTearDown(session.dispose);
    session.processObservation(frame(0, 170, .5));
    session.start();
    for (final sample in [
      frame(150, 135, .43),
      frame(300, 90, .32),
      frame(500, 90, .32),
      frame(650, 90, .32, aligned: false),
      frame(800, 170, .5),
      frame(1100, 170, .5),
    ]) {
      session.processObservation(sample);
    }
    expect(session.reps, 0);
    expect(session.phase, TrainingPhase.active);
  });

  test('a visible side switch discards the partial rep and re-arms', () {
    final session = TrainingSessionController(
      movement: TrainingMovement.pushUp,
    );
    addTearDown(session.dispose);
    session.processObservation(frame(0, 170, .5));
    session.start();
    for (final sample in [
      frame(150, 135, .43),
      frame(300, 90, .32),
      frame(500, 90, .32),
      frame(650, 90, .32, side: PushUpSide.right),
      frame(800, 170, .5, side: PushUpSide.right),
      frame(950, 135, .43, side: PushUpSide.right),
      frame(1100, 90, .32, side: PushUpSide.right),
      frame(1300, 90, .32, side: PushUpSide.right),
      frame(1500, 170, .5, side: PushUpSide.right),
      frame(1800, 170, .5, side: PushUpSide.right),
    ]) {
      session.processObservation(sample);
    }
    expect(session.reps, 1);
    expect(session.phase, TrainingPhase.active);
  });

  test('push-up series retains its exercise and only confirmed reps count', () {
    final session = TrainingSessionController(
      movement: TrainingMovement.pushUp,
    );
    addTearDown(session.dispose);
    session.processObservation(frame(0, 170, .5));
    session.start();
    for (final sample in [
      frame(150, 135, .43),
      frame(300, 90, .32),
      frame(500, 90, .32),
      frame(700, 170, .5),
      frame(1000, 170, .5),
    ]) {
      session.processObservation(sample);
    }
    session.finish();
    final result = TrainingSessionResult.fromJson(session.result!.toJson());
    expect(result.exerciseId, 'lagartijas');
    expect(result.rulesVersion, 'lagartijas-v1');
    expect(result.validReps, 1);
    final pending = SavedTrainingSession(
      ownerId: 'athlete',
      result: result,
      state: SavedSessionState.pending,
    );
    expect(TrainingProgress.fromSessions([pending]).chestArmReps, 0);
    final squat = TrainingSessionResult.fromJson({
      ...result.toJson(),
      'session_id': 'squat',
      'exercise_id': TrainingMovement.squat.id,
      'rules_version': TrainingMovement.squat.rulesVersion,
      'valid_reps': 3,
    });
    final progress = TrainingProgress.fromSessions([
      pending,
      pending.withSync(state: SavedSessionState.confirmed),
      SavedTrainingSession(
        ownerId: 'athlete',
        result: squat,
        state: SavedSessionState.confirmed,
      ),
    ]);
    expect(progress.chestArmReps, 1);
    expect(progress.legReps, 3);
    expect(progress.confirmedReps, 4);
    expect(progress.pendingReps, 0);
  });
}
