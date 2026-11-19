import 'training_session.dart';

enum SavedSessionState { draft, pending, confirmed, rejected }

class SavedTrainingSession {
  final String ownerId;
  final TrainingSessionResult result;
  final SavedSessionState state;
  final int attempts;
  final DateTime? retryAfter;
  final String? error;

  const SavedTrainingSession({
    required this.ownerId,
    required this.result,
    required this.state,
    this.attempts = 0,
    this.retryAfter,
    this.error,
  });

  SavedTrainingSession withSync({
    required SavedSessionState state,
    int? attempts,
    DateTime? retryAfter,
    String? error,
  }) => SavedTrainingSession(
    ownerId: ownerId,
    result: result,
    state: state,
    attempts: attempts ?? this.attempts,
    retryAfter: retryAfter,
    error: error,
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'owner_id': ownerId,
    'result': result.toJson(),
    'state': state.name,
    'attempts': attempts,
    'retry_after': retryAfter?.toUtc().toIso8601String(),
    'error': error,
  };

  factory SavedTrainingSession.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported session version');
    }
    return SavedTrainingSession(
      ownerId: json['owner_id'] as String,
      result: TrainingSessionResult.fromJson(
        json['result'] as Map<String, dynamic>,
      ),
      state: SavedSessionState.values.byName(json['state'] as String),
      attempts: json['attempts'] as int,
      retryAfter: json['retry_after'] == null
          ? null
          : DateTime.parse(json['retry_after'] as String),
      error: json['error'] as String?,
    );
  }
}
