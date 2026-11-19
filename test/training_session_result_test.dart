import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';

void main() {
  TrainingSessionResult result({
    int reps = 1,
    TrainingSource source = TrainingSource.camera,
    Duration activeDuration = const Duration(seconds: 5),
  }) => TrainingSessionResult(
    sessionId: createTrainingSessionId(),
    exerciseId: SquatSessionRules.exerciseId,
    rulesVersion: SquatSessionRules.version,
    source: source,
    startedAtUtc: DateTime.utc(2026, 11, 18),
    endedAtUtc: DateTime.utc(2026, 11, 18, 0, 0, 10),
    activeDuration: activeDuration,
    validReps: reps,
  );

  test('invalid counts and durations cannot become a session result', () {
    expect(() => result(reps: -1), throwsArgumentError);
    expect(
      () => result(activeDuration: const Duration(seconds: 11)),
      throwsArgumentError,
    );
    expect(
      () => result(activeDuration: const Duration(seconds: -1)),
      throwsArgumentError,
    );
  });

  test('zero repetitions and simulation are excluded from submission', () {
    expect(result(reps: 0).eligibleForSubmission, isFalse);
    expect(
      result(source: TrainingSource.simulation).eligibleForSubmission,
      isFalse,
    );
    expect(result().eligibleForSubmission, isTrue);
  });

  test('generated identities are version 4 UUIDs', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = List.generate(100, (_) => createTrainingSessionId());
    expect(ids.every(pattern.hasMatch), isTrue);
    expect(ids.toSet().length, ids.length);
  });
}
