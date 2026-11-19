import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/training_session_file_store.dart';
import '../../data/datasources/training_session_supabase_remote.dart';
import '../../data/repositories/training_session_repository.dart';
import '../../domain/models/saved_training_session.dart';

final trainingLeaguePointsProvider = FutureProvider.autoDispose
    .family<int, String>((ref, sessionId) async {
      final owner = ref.watch(
        authControllerProvider.select((state) => state.user?.id),
      );
      if (owner == null) throw StateError('No session account');
      final row = await Supabase.instance.client
          .from('sessions')
          .select('league_id, verified_reps')
          .eq('id', sessionId)
          .eq('user_id', owner)
          .single()
          .timeout(const Duration(seconds: 12));
      return row['league_id'] == null
          ? 0
          : (row['verified_reps'] as num).toInt();
    });

final trainingSessionRepositoryProvider =
    FutureProvider.autoDispose<TrainingSessionRepository?>((ref) async {
      final owner = ref.watch(
        authControllerProvider.select((state) => state.user?.id),
      );
      if (owner == null) return null;
      var disposed = false;
      TrainingSessionRepository? repository;
      ref.onDispose(() {
        disposed = true;
        repository?.dispose();
      });
      final root = await getApplicationDocumentsDirectory();
      if (disposed) return null;
      final client = Supabase.instance.client;
      repository = TrainingSessionRepository(
        store: TrainingSessionFileStore(root: root, ownerId: owner),
        remote: TrainingSessionSupabaseRemote(
          client,
          enabled: const bool.fromEnvironment('TRAINING_SYNC_ENABLED'),
        ),
        currentOwner: () => client.auth.currentUser?.id ?? '',
      );
      return repository;
    });

final savedTrainingSessionsProvider =
    StreamProvider.autoDispose<List<SavedTrainingSession>>((ref) async* {
      final repository = await ref.watch(
        trainingSessionRepositoryProvider.future,
      );
      if (repository == null) {
        yield [];
        return;
      }
      await repository.load();
      yield repository.records;
      unawaited(repository.sync().catchError((Object _) {}));
      await for (final _ in repository.changes) {
        yield repository.records;
      }
    });
