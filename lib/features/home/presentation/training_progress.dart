import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercise/domain/models/saved_training_session.dart';
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

  const TrainingProgress(this.confirmedReps, this.pendingReps);

  factory TrainingProgress.fromSessions(List<SavedTrainingSession> sessions) {
    final confirmed = <String, int>{};
    final pending = <String, int>{};
    for (final session in sessions) {
      final result = session.result;
      if (!result.eligibleForSubmission) continue;
      if (session.state == SavedSessionState.confirmed) {
        confirmed[result.sessionId] = result.validReps;
      } else if (session.state == SavedSessionState.pending) {
        pending[result.sessionId] = result.validReps;
      }
    }
    pending.removeWhere((id, _) => confirmed.containsKey(id));
    return TrainingProgress(
      confirmed.values.fold(0, (sum, reps) => sum + reps),
      pending.values.fold(0, (sum, reps) => sum + reps),
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
