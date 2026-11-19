import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/saved_training_session.dart';
import '../../domain/repositories/training_session_remote.dart';

class TrainingSessionSupabaseRemote implements TrainingSessionRemote {
  final SupabaseClient client;
  @override
  final bool enabled;

  TrainingSessionSupabaseRemote(this.client, {this.enabled = false});

  @override
  Future<void> submit(SavedTrainingSession session) async {
    if (!enabled || client.auth.currentUser?.id != session.ownerId) {
      throw StateError('Session owner is not authenticated');
    }
    final result = session.result;
    if (!result.eligibleForSubmission) throw const TrainingSessionRejected();
    try {
      final response = await client
          .rpc(
            'submit_training_session_v1',
            params: {
              'p_id': result.sessionId,
              'p_owner': session.ownerId,
              'p_exercise': result.exerciseId,
              'p_rules': result.rulesVersion,
              'p_source': result.source.name,
              'p_started_at': result.startedAtUtc.toIso8601String(),
              'p_ended_at': result.endedAtUtc.toIso8601String(),
              'p_active_us': result.activeDuration.inMicroseconds,
              'p_reps': result.validReps,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response is! Map ||
          response['session_id'] != result.sessionId ||
          response['status'] != 'stored') {
        throw StateError('Invalid session receipt');
      }
    } on PostgrestException catch (error) {
      if (error.code == '22023' || error.code == '23514') {
        throw const TrainingSessionRejected();
      }
      rethrow;
    }
  }
}
