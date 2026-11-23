import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercise/domain/models/saved_training_session.dart';
import '../../exercise/domain/models/training_session.dart';
import '../../exercise/presentation/controllers/training_storage_providers.dart';

final trainingProgressProvider = Provider.autoDispose(
  (ref) => ref
      .watch(savedTrainingSessionsProvider)
      .whenData(TrainingProgress.fromSessions),
);

class TrainingProgress {
  static const ranks = [
    'Novato',
    'Principiante',
    'Intermedio',
    'Avanzado',
    'Maestro',
  ];
  static const thresholds = [0, 50, 500, 2000, 10000];

  final int confirmedReps;
  final int pendingReps;
  final int legReps;
  final int chestArmReps;

  const TrainingProgress(
    this.confirmedReps,
    this.pendingReps, {
    this.legReps = 0,
    this.chestArmReps = 0,
  });

  factory TrainingProgress.fromSessions(List<SavedTrainingSession> sessions) {
    final confirmed = <String, TrainingSessionResult>{};
    final pending = <String, int>{};
    for (final session in sessions) {
      final result = session.result;
      if (!result.eligibleForSubmission) continue;
      if (session.state == SavedSessionState.confirmed) {
        confirmed[result.sessionId] = result;
      } else if (session.state == SavedSessionState.pending) {
        pending[result.sessionId] = result.validReps;
      }
    }
    pending.removeWhere((id, _) => confirmed.containsKey(id));
    var legReps = 0;
    var chestArmReps = 0;
    var total = 0;
    for (final result in confirmed.values) {
      total += result.validReps;
      switch (TrainingMovement.forId(result.exerciseId)) {
        case TrainingMovement.squat:
          legReps += result.validReps;
        case TrainingMovement.pushUp:
          chestArmReps += result.validReps;
        case TrainingMovement.crunch || TrainingMovement.plank || null:
          break;
      }
    }
    return TrainingProgress(
      total,
      pending.values.fold(0, (sum, reps) => sum + reps),
      legReps: legReps,
      chestArmReps: chestArmReps,
    );
  }

  int get level => thresholds.lastIndexWhere((value) => confirmedReps >= value);
  String get rank => ranks[level];
  bool get atMaximum => level == ranks.length - 1;
  double get fraction => atMaximum
      ? 1
      : (confirmedReps - thresholds[level]) /
            (thresholds[level + 1] - thresholds[level]);
  String get rankCaption => atMaximum
      ? '$confirmedReps repeticiones confirmadas'
      : '$confirmedReps de ${thresholds[level + 1]} reps para ${ranks[level + 1]}';
  List<String> get trophies => [if (confirmedReps >= thresholds[2]) 'Guerrero'];
}
