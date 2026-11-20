// Run from the repository root:
// .fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart.exe run scripts/verify_training_storage.dart
// Pure Dart checks: no Flutter test socket or live backend is required.
import 'dart:io';

import 'package:rivalfit/features/exercise/data/datasources/training_session_file_store.dart';
import 'package:rivalfit/features/exercise/data/repositories/training_session_repository.dart';
import 'package:rivalfit/features/exercise/domain/models/saved_training_session.dart';
import 'package:rivalfit/features/exercise/domain/models/training_session.dart';
import 'package:rivalfit/features/exercise/domain/repositories/training_session_remote.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

class FakeRemote implements TrainingSessionRemote {
  @override
  bool enabled = true;
  final stored = <String>{};
  final history = <SavedTrainingSession>[];
  int calls = 0;
  bool loseNextResponse = false;
  bool reject = false;
  bool offline = false;

  @override
  Future<List<SavedTrainingSession>> fetchHistory(String ownerId) async {
    if (offline) throw const SocketException('No connection');
    return history;
  }

  @override
  Future<void> submit(SavedTrainingSession session) async {
    calls++;
    if (offline) throw const SocketException('No connection');
    if (reject) throw const TrainingSessionRejected();
    stored.add(session.result.sessionId);
    if (loseNextResponse) {
      loseNextResponse = false;
      throw const SocketException('Response lost after server commit');
    }
  }
}

Future<void> idle(TrainingSessionRepository repository) async {
  for (var i = 0; i < 500; i++) {
    if (!repository.syncing) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('Sync did not finish');
}

Future<void> main() async {
  final root = Directory(
    'build/training-storage-check-${DateTime.now().microsecondsSinceEpoch}',
  );
  await root.create(recursive: true);
  final repositories = <TrainingSessionRepository>[];
  var owner = 'account-a';
  final store = TrainingSessionFileStore(root: root, ownerId: owner);
  final remote = FakeRemote();
  TrainingSessionRepository repository(
    TrainingSessionFileStore files,
    FakeRemote api,
  ) {
    final value = TrainingSessionRepository(
      store: files,
      remote: api,
      currentOwner: () => owner,
    );
    repositories.add(value);
    return value;
  }

  TrainingSessionResult result({
    String? id,
    TrainingSource source = TrainingSource.camera,
  }) => TrainingSessionResult(
    sessionId: id ?? createTrainingSessionId(),
    exerciseId: SquatSessionRules.exerciseId,
    rulesVersion: SquatSessionRules.version,
    source: source,
    startedAtUtc: DateTime.utc(2026, 11, 18),
    endedAtUtc: DateTime.utc(2026, 11, 18, 0, 0, 12),
    activeDuration: const Duration(seconds: 10, microseconds: 123),
    validReps: 3,
  );
  try {
    final first = repository(store, remote);
    final workout = result();
    await first.checkpoint(workout);
    first.dispose();
    final restored = repository(store, remote);
    await restored.load();
    check(
      restored.records.single.state == SavedSessionState.draft,
      'Draft not recovered',
    );
    check(
      restored.records.single.result.activeDuration == workout.activeDuration,
      'Duration changed',
    );
    remote.loseNextResponse = true;
    await restored.complete(workout);
    await idle(restored);
    check(
      restored.records.single.state == SavedSessionState.pending,
      'Lost response must remain pending',
    );
    check(
      remote.stored.length == 1 && remote.calls == 1,
      'First submission mismatch',
    );
    await restored.sync();
    check(remote.calls == 1, 'Backoff ignored');
    await restored.sync(force: true);
    check(
      restored.records.single.state == SavedSessionState.confirmed,
      'Retry not confirmed',
    );
    check(
      remote.stored.length == 1 && remote.calls == 2,
      'Retry duplicated result',
    );
    await restored.complete(workout);
    await restored.checkpoint(workout);
    check(
      (await store.load()).single.state == SavedSessionState.confirmed,
      'Late checkpoint undid completion',
    );
    check(remote.calls == 2, 'Duplicate finalization sent another request');

    final savedBeforeReinstall = restored.records.single;
    final cloudOnly = FakeRemote()..enabled = false;
    cloudOnly.history.add(savedBeforeReinstall);
    final newInstall = repository(
      TrainingSessionFileStore(
        root: Directory('${root.path}/new-install'),
        ownerId: owner,
      ),
      cloudOnly,
    );
    await newInstall.load();
    check(newInstall.records.isEmpty, 'A new installation should start empty');
    cloudOnly.offline = true;
    await newInstall.sync();
    check(newInstall.records.isEmpty, 'Offline startup must remain usable');
    cloudOnly.offline = false;
    await newInstall.sync();
    await newInstall.sync();
    check(
      newInstall.records.single.state == SavedSessionState.confirmed &&
          newInstall.records.single.result.sessionId == workout.sessionId &&
          newInstall.records.single.result.validReps == workout.validReps &&
          cloudOnly.calls == 0,
      'Reinstall did not restore the confirmed result exactly once',
    );

    final reconnectRemote = FakeRemote()..offline = true;
    final reconnectStore = TrainingSessionFileStore(
      root: Directory('${root.path}/reconnect'),
      ownerId: owner,
    );
    final offlineWorkout = result();
    final withoutNetwork = repository(reconnectStore, reconnectRemote);
    await withoutNetwork.complete(offlineWorkout);
    await idle(withoutNetwork);
    check(
      reconnectRemote.calls == 1 &&
          reconnectRemote.stored.isEmpty &&
          withoutNetwork.records.single.state == SavedSessionState.pending,
      'Offline submission did not stay pending',
    );
    withoutNetwork.dispose();
    final reopened = repository(reconnectStore, reconnectRemote);
    await reopened.load();
    check(
      reopened.records.single.state == SavedSessionState.pending &&
          reopened.records.single.result.sessionId == offlineWorkout.sessionId,
      'Offline result was lost or changed after reopening',
    );
    reconnectRemote.offline = false;
    await reopened.sync(force: true);
    await reopened.sync(force: true);
    check(
      reopened.records.single.state == SavedSessionState.confirmed &&
          reopened.records.single.result.validReps ==
              offlineWorkout.validReps &&
          reconnectRemote.stored.single == offlineWorkout.sessionId &&
          reconnectRemote.calls == 2,
      'Reconnection did not confirm the original result exactly once',
    );

    final otherStore = TrainingSessionFileStore(
      root: root,
      ownerId: 'account-b',
    );
    check((await otherStore.load()).isEmpty, 'Account data leaked');
    final offline = FakeRemote()..enabled = false;
    final offlineRepo = repository(store, offline);
    final pending = result();
    await offlineRepo.complete(pending);
    check(offline.calls == 0, 'Disabled backend received data');
    owner = 'account-b';
    offline.enabled = true;
    await offlineRepo.sync(force: true);
    check(offline.calls == 0, 'Wrong account uploaded a session');
    owner = 'account-a';

    final rejectedRemote = FakeRemote()..reject = true;
    final rejectedRepo = repository(store, rejectedRemote);
    await rejectedRepo.sync(force: true);
    check(
      rejectedRepo.records.any(
        (r) =>
            r.result.sessionId == pending.sessionId &&
            r.state == SavedSessionState.rejected,
      ),
      'Rejected session not retained',
    );

    final mainFile = File(
      '${root.path}/training_sessions_v1/account-a/${workout.sessionId}.json',
    );
    await mainFile.writeAsString('{broken', flush: true);
    final recovered = await store.load();
    check(
      recovered.any(
        (r) =>
            r.result.sessionId == workout.sessionId && r.result.validReps == 3,
      ),
      'Backup recovery failed',
    );

    final simulation = result(source: TrainingSource.simulation);
    final isolated = TrainingSessionFileStore(
      root: root,
      ownerId: 'simulation',
    );
    owner = 'simulation';
    final simRepo = repository(isolated, FakeRemote());
    await simRepo.checkpoint(simulation);
    await simRepo.complete(simulation);
    check((await isolated.load()).isEmpty, 'Simulation entered the sync queue');

    final blocked = File('${root.path}/blocked');
    await blocked.writeAsString('not a directory');
    final blockedStore = TrainingSessionFileStore(
      root: Directory(blocked.path),
      ownerId: 'simulation',
    );
    var failed = false;
    try {
      await blockedStore.save(
        SavedTrainingSession(
          ownerId: 'simulation',
          result: result(),
          state: SavedSessionState.pending,
        ),
      );
    } on FileSystemException {
      failed = true;
    }
    check(failed, 'Storage errors were hidden');
    stdout.writeln(
      'OK: restart, offline reopen and reconnect, microseconds, lost response, backoff, duplicate completion, account isolation, rejection, backup, simulation and disk errors.',
    );
  } finally {
    for (final repository in repositories) {
      repository.dispose();
    }
    // Only delete the explicitly created test directory inside this checkout.
    final checkout = (await Directory.current.resolveSymbolicLinks())
        .replaceAll('\\', '/');
    final buildRoot = (await Directory(
      'build',
    ).resolveSymbolicLinks()).replaceAll('\\', '/');
    final target = (await root.resolveSymbolicLinks()).replaceAll('\\', '/');
    if (buildRoot != '$checkout/build' ||
        !target.startsWith('$buildRoot/training-storage-check-')) {
      throw StateError('Unexpected cleanup target');
    }
    await root.delete(recursive: true);
  }
}
