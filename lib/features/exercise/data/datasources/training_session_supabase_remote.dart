import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/saved_training_session.dart';
import '../../domain/models/training_session.dart';
import '../../domain/repositories/training_session_remote.dart';

class TrainingSessionSupabaseRemote implements TrainingSessionRemote {
  final SupabaseClient client;
  @override
  final bool enabled;

  TrainingSessionSupabaseRemote(this.client, {this.enabled = false});

  @override
  Future<List<SavedTrainingSession>> fetchHistory(String ownerId) async {
    const pageSize = 200;
    final records = <SavedTrainingSession>[];
    String? cursor;
    while (true) {
      if (client.auth.currentUser?.id != ownerId) {
        throw StateError('Session owner is not authenticated');
      }
      var query = client
          .from('sessions')
          .select(
            'id,user_id,exercise_type,rules_version,platform,started_at,completed_at,active_duration_us,verified_reps',
          )
          .eq('user_id', ownerId)
          .eq('platform', TrainingSource.camera.name)
          .inFilter('rules_version', const [
            SquatSessionRules.version,
            'lagartijas-v1',
          ]);
      if (cursor != null) query = query.gt('id', cursor);
      final page = await query
          .order('id', ascending: true)
          .limit(pageSize)
          .timeout(const Duration(seconds: 12));
      for (final row in page) {
        final movement = TrainingMovement.forId(row['exercise_type'] as String);
        if (row['user_id'] != ownerId ||
            movement == null ||
            row['rules_version'] != movement.rulesVersion) {
          continue;
        }
        final result = TrainingSessionResult.fromJson({
          'session_id': row['id'],
          'exercise_id': row['exercise_type'],
          'rules_version': row['rules_version'],
          'source': row['platform'],
          'started_at': row['started_at'],
          'ended_at': row['completed_at'],
          'active_duration_us': row['active_duration_us'],
          'valid_reps': row['verified_reps'],
        });
        if (result.eligibleForSubmission) {
          records.add(
            SavedTrainingSession(
              ownerId: ownerId,
              result: result,
              state: SavedSessionState.confirmed,
            ),
          );
        }
      }
      if (page.length < pageSize) return records;
      cursor = page.last['id'] as String;
    }
  }

  @override
  Future<void> submit(SavedTrainingSession session) async {
    if (!enabled || client.auth.currentUser?.id != session.ownerId) {
      throw StateError('Session owner is not authenticated');
    }
    final result = session.result;
    if (!result.eligibleForSubmission) throw const TrainingSessionRejected();
    const pushUp = TrainingMovement.pushUp;
    final isPushUp =
        result.exerciseId == pushUp.id &&
        result.rulesVersion == pushUp.rulesVersion;
    try {
      final response = await client
          .rpc(
            isPushUp
                ? 'submit_push_up_session_v1'
                : 'submit_training_session_v1',
            params: {
              'p_id': result.sessionId,
              'p_owner': session.ownerId,
              if (!isPushUp) ...{
                'p_exercise': result.exerciseId,
                'p_rules': result.rulesVersion,
              },
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
