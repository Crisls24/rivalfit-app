import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';
import 'package:rivalfit/features/exercise/domain/models/posture_readiness.dart';
import 'package:rivalfit/features/exercise/domain/models/squat_observation.dart';
import 'package:rivalfit/features/exercise/presentation/controllers/training_session_controller.dart';

void main() {
  late TrainingSessionController session;

  setUp(() => session = TrainingSessionController());
  tearDown(() => session.dispose());

  test('first descent starts immediately and survives one missing sample', () {
    void frame(int ms, double angle, {bool visible = true}) {
      session.processObservation(
        SquatObservation(
          timestamp: Duration(milliseconds: ms),
          readiness: PostureReadiness(visible, visible && angle >= 160, ''),
          leftKneeAngle: angle,
          rightKneeAngle: angle,
          hipHeight: angle <= 105 ? 0.33 : 0.50,
        ),
      );
    }

    frame(0, 170);
    session.start();
    frame(150, 135);
    frame(300, 100);
    frame(450, 0, visible: false);
    expect(session.phase, TrainingPhase.active);
    expect(session.feedback, 'Fuera de cuadro');
    frame(600, 100);
    frame(900, 100);
    frame(1050, 170);
    frame(1350, 170);
    expect(session.reps, 1);
    frame(1500, 100);
    frame(2300, 0, visible: false);
    expect(session.phase, TrainingPhase.recovering);
    frame(2450, 170);
    frame(2750, 170);
    expect(session.reps, 1);
  });

  testWidgets('tracking timeout preserves confirmed reps and finalizes once', (
    tester,
  ) async {
    session.processObservation(
      const SquatObservation(
        timestamp: Duration.zero,
        readiness: PostureReadiness(true, true, 'Postura lista'),
        leftKneeAngle: 170,
        rightKneeAngle: 170,
        hipHeight: 0.5,
      ),
    );
    session.start();
    session.recordValidRep();
    const missingFor = Duration(seconds: 1);
    await tester.pump(missingFor);
    session.processObservation(
      const SquatObservation(
        timestamp: missingFor,
        readiness: PostureReadiness(false, false, ''),
        leftKneeAngle: double.nan,
        rightKneeAngle: double.nan,
        hipHeight: double.nan,
      ),
    );

    const lastMillisecond = Duration(milliseconds: 1);
    await tester.pump(
      TrainingSessionController.trackingLossLimit -
          missingFor -
          lastMillisecond,
    );
    expect(session.phase, TrainingPhase.recovering);
    expect(session.result, isNull);

    await tester.pump(lastMillisecond);
    final result = session.result!;
    expect(result.validReps, 1);
    expect(session.phase, TrainingPhase.finished);
    expect(session.endedAfterTrackingLoss, isTrue);
    session.updatePosture(ready: true);
    session.finish();
    expect(session.result, same(result));
    session.prepareAnotherSeries();
    expect(session.endedAfterTrackingLoss, isFalse);
  });

  testWidgets('returning into frame cancels timeout before posture is ready', (
    tester,
  ) async {
    session.updatePosture(ready: true);
    session.start();
    session.updatePosture(ready: false);
    await tester.pump(const Duration(seconds: 6));
    session.processObservation(
      const SquatObservation(
        timestamp: Duration(seconds: 6),
        readiness: PostureReadiness(true, false, 'Ponte de pie'),
        leftKneeAngle: 145,
        rightKneeAngle: 145,
        hipHeight: 0.4,
      ),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(session.phase, TrainingPhase.recovering);
    expect(session.feedback, 'Ponte de pie');
    expect(session.result, isNull);

    session.updatePosture(ready: true);
    expect(session.phase, TrainingPhase.active);
  });

  testWidgets('manual pause cancels the automatic finish', (tester) async {
    session.updatePosture(ready: true);
    session.start();
    session.updatePosture(ready: false);
    await tester.pump(const Duration(seconds: 6));
    session.pause();
    await tester.pump(TrainingSessionController.trackingLossLimit);
    expect(session.phase, TrainingPhase.paused);
    expect(session.result, isNull);

    session.resume();
    session.updatePosture(ready: true);
    await tester.pump(TrainingSessionController.trackingLossLimit);
    expect(session.phase, TrainingPhase.active);
    expect(session.endedAfterTrackingLoss, isFalse);
  });

  test('detector cycles count only during activity and reset on pause', () {
    void observe(int ms, double angle) => session.processObservation(
      SquatObservation(
        timestamp: Duration(milliseconds: ms),
        readiness: PostureReadiness(true, angle >= 160, 'Postura lista'),
        leftKneeAngle: angle,
        rightKneeAngle: angle,
        hipHeight: angle <= 105 ? 0.33 : 0.50,
      ),
    );
    observe(0, 170);
    session.start();
    for (final p in [
      [100, 170],
      [400, 170],
      [550, 135],
      [700, 100],
      [900, 100],
      [1100, 170],
      [1400, 170],
    ]) {
      observe(p[0], p[1].toDouble());
    }
    expect(session.reps, 1);
    observe(1550, 100);
    observe(1750, 100);
    session.pause();
    observe(1900, 170);
    expect(session.reps, 1);
    session.resume();
    observe(2200, 170);
    observe(2500, 170);
    expect(session.reps, 1);
    session.finish();
    observe(2800, 100);
    expect(session.result!.validReps, 1);
  });

  test('requires posture before starting and ignores inactive repetitions', () {
    session.start();
    session.recordValidRep();
    expect(session.phase, TrainingPhase.preparation);
    expect(session.reps, 0);
    session.updatePosture(ready: true);
    session.start();
    session.recordValidRep();
    expect(session.reps, 1);
  });

  test('posture loss and pause block counting until posture is recovered', () {
    session.updatePosture(ready: true);
    session.start();
    session.updatePosture(ready: false);
    session.recordValidRep();
    expect(session.phase, TrainingPhase.recovering);
    expect(session.reps, 0);
    session.updatePosture(ready: true);
    session.recordValidRep();
    session.pause();
    session.updatePosture(ready: true);
    expect(session.phase, TrainingPhase.paused);
    session.resume();
    session.recordValidRep();
    expect(session.reps, 1);
    expect(session.phase, TrainingPhase.recovering);
    session.updatePosture(ready: true);
    session.recordValidRep();
    expect(session.reps, 2);
  });

  test('finishing freezes the result and is idempotent', () {
    session.updatePosture(ready: true);
    session.start();
    session.recordValidRep();
    session.finish();
    final result = session.result;
    final duration = session.activeDuration;
    session.finish();
    session.recordValidRep();
    session.updatePosture(ready: false);
    session.resume();
    expect(session.phase, TrainingPhase.finished);
    expect(session.reps, 1);
    expect(session.activeDuration, duration);
    expect(identical(session.result, result), isTrue);
    expect(result!.validReps, 1);
    expect(result.sessionId, session.sessionId);
  });

  test('another series starts fresh and keeps the previous result intact', () {
    var created = 0;
    final workout = TrainingSessionController(
      createId: () => 'series-${++created}',
    );
    addTearDown(workout.dispose);
    workout.updatePosture(ready: true);
    workout.start();
    workout.recordValidRep();
    workout.prepareAnotherSeries();
    expect(workout.phase, TrainingPhase.active);

    workout.finish();
    final first = workout.result!;
    workout.prepareAnotherSeries();
    expect(workout.phase, TrainingPhase.preparation);
    expect(workout.sessionId, isNull);
    expect(workout.result, isNull);
    expect(workout.activeDuration, Duration.zero);
    expect(workout.reps, 0);
    workout.start();
    expect(workout.phase, TrainingPhase.preparation);
    workout.updatePosture(ready: true);
    workout.start();
    expect(workout.sessionId, 'series-2');
    expect(first.sessionId, 'series-1');
    expect(first.validReps, 1);
  });

  test(
    'identity is created once at start and simulation cannot be submitted',
    () {
      var created = 0;
      final preview = TrainingSessionController(
        source: TrainingSource.simulation,
        createId: () => 'session-${++created}',
      );
      addTearDown(preview.dispose);
      expect(preview.sessionId, isNull);
      preview.updatePosture(ready: true);
      preview.start();
      preview.start();
      preview.recordValidRep();
      preview.pause();
      preview.resume();
      preview.updatePosture(ready: true);
      preview.finish();
      expect(created, 1);
      expect(preview.result!.sessionId, 'session-1');
      expect(preview.result!.eligibleForSubmission, isFalse);
      expect(preview.syncStatus, SessionSyncStatus.notSaved);
    },
  );
}
