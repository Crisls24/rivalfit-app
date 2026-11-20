import '../models/saved_training_session.dart';

abstract interface class TrainingSessionRemote {
  bool get enabled;
  Future<void> submit(SavedTrainingSession session);
  Future<List<SavedTrainingSession>> fetchHistory(String ownerId);
}

class TrainingSessionRejected implements Exception {
  const TrainingSessionRejected();
}
