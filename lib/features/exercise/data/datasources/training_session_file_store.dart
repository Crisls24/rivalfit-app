import 'dart:convert';
import 'dart:io';

import '../../domain/models/saved_training_session.dart';

/// Serialized, account-scoped writes. Each committed record has a backup;
/// temporary files never replace a valid result before being fully flushed.
class TrainingSessionFileStore {
  final Directory root;
  final String ownerId;
  Future<void> _tail = Future.value();

  TrainingSessionFileStore({required this.root, required this.ownerId}) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(ownerId)) {
      throw ArgumentError('Invalid owner');
    }
  }

  Directory get _directory =>
      Directory('${root.path}/training_sessions_v1/$ownerId');

  Future<T> _serialize<T>(Future<T> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  String _path(String id) {
    if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id)) {
      throw ArgumentError('Invalid session ID');
    }
    return '${_directory.path}/$id.json';
  }

  Future<SavedTrainingSession?> _read(String id) async {
    final path = _path(id);
    Object? failure;
    for (final name in [path, '$path.bak']) {
      final file = File(name);
      if (!await file.exists()) continue;
      try {
        final record = SavedTrainingSession.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
        if (record.ownerId != ownerId || record.result.sessionId != id) {
          throw const FormatException('Session identity mismatch');
        }
        return record;
      } catch (error) {
        failure = error;
      }
    }
    if (failure != null) {
      throw FormatException('Cannot recover saved session: $id');
    }
    return null;
  }

  Future<List<SavedTrainingSession>> load() => _serialize(() async {
    if (!await _directory.exists()) return [];
    final ids = <String>{};
    await for (final file in _directory.list()) {
      if (file is! File) continue;
      final name = file.uri.pathSegments.last;
      if (name.endsWith('.json')) ids.add(name.substring(0, name.length - 5));
      if (name.endsWith('.json.bak')) {
        ids.add(name.substring(0, name.length - 9));
      }
    }
    final records = <SavedTrainingSession>[];
    for (final id in ids) {
      final record = await _read(id);
      if (record != null) records.add(record);
    }
    records.sort(
      (a, b) => b.result.startedAtUtc.compareTo(a.result.startedAtUtc),
    );
    return records;
  });

  Future<void> save(SavedTrainingSession record) => _serialize(() async {
    if (record.ownerId != ownerId) throw ArgumentError('Wrong owner');
    await _directory.create(recursive: true);
    final path = _path(record.result.sessionId);
    final previous = await _read(record.result.sessionId);
    // A delayed checkpoint can never undo a completed session.
    if (previous != null &&
        previous.state != SavedSessionState.draft &&
        record.state == SavedSessionState.draft) {
      return;
    }
    if (previous != null &&
        (previous.state == SavedSessionState.confirmed ||
            previous.state == SavedSessionState.rejected) &&
        record.state != previous.state) {
      return;
    }
    if (previous != null &&
        previous.state != SavedSessionState.draft &&
        jsonEncode(previous.result.toJson()) !=
            jsonEncode(record.result.toJson())) {
      throw StateError('Completed results cannot be changed');
    }
    final file = File(path);
    final backup = File('$path.bak');
    final temporary = File('$path.tmp');
    await temporary.writeAsString(jsonEncode(record.toJson()), flush: true);
    if (await file.exists()) {
      // Keep a readable backup even if recovering from a corrupt main file.
      await backup.writeAsString(jsonEncode(previous!.toJson()), flush: true);
      await file.delete();
    }
    await temporary.rename(path);
  });

  Future<void> deleteDraft(String id) => _serialize(() async {
    final record = await _read(id);
    if (record != null && record.state != SavedSessionState.draft) return;
    for (final suffix in ['', '.bak', '.tmp']) {
      final file = File('${_path(id)}$suffix');
      if (await file.exists()) await file.delete();
    }
  });
}
