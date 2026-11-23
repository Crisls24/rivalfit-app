import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../domain/models/saved_training_session.dart';
import '../../domain/models/training_session.dart';
import '../../domain/repositories/training_session_remote.dart';
import '../datasources/training_session_file_store.dart';

class TrainingSessionRepository {
  final TrainingSessionFileStore store;
  final TrainingSessionRemote remote;
  final String Function() currentOwner;
  final DateTime Function() now;
  final _changes = StreamController<void>.broadcast();
  List<SavedTrainingSession> _records = [];
  Future<void>? _loading;
  bool _syncing = false;
  bool _historyRestored = false;
  bool _closed = false;
  Timer? _timer;

  TrainingSessionRepository({
    required this.store,
    required this.remote,
    required this.currentOwner,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(sync().catchError((Object _) {}));
    });
  }

  List<SavedTrainingSession> get records => List.unmodifiable(_records);
  Stream<void> get changes => _changes.stream;
  bool get syncing => _syncing;
  bool get _ownsAccount => !_closed && currentOwner() == store.ownerId;

  Future<void> load() => _loading ??= _refresh().catchError((Object error) {
    _loading = null;
    throw error;
  });

  void _emit() {
    if (!_closed) _changes.add(null);
  }

  Future<void> _refresh() async {
    _records = await store.load();
    _emit();
  }

  Future<void> checkpoint(TrainingSessionResult result) async {
    if (!_ownsAccount) throw StateError('Session account changed');
    await load();
    await store.save(
      SavedTrainingSession(
        ownerId: store.ownerId,
        result: result,
        state: SavedSessionState.draft,
      ),
    );
    await _refresh();
  }

  Future<void> complete(TrainingSessionResult result) async {
    if (!_ownsAccount) throw StateError('Session account changed');
    await load();
    if (!result.eligibleForSubmission && !result.eligibleForLocalHistory) {
      await discardDraft(result.sessionId);
      return;
    }
    final existing = _records.where(
      (r) => r.result.sessionId == result.sessionId,
    );
    if (existing.isNotEmpty &&
        existing.first.state != SavedSessionState.draft) {
      if (jsonEncode(existing.first.result.toJson()) !=
          jsonEncode(result.toJson())) {
        throw StateError('Session identity conflict');
      }
      return;
    }
    await store.save(
      SavedTrainingSession(
        ownerId: store.ownerId,
        result: result,
        state: result.eligibleForSubmission
            ? SavedSessionState.pending
            : SavedSessionState.personal,
      ),
    );
    await _refresh();
    if (result.eligibleForSubmission) {
      unawaited(sync().catchError((Object _) {}));
    }
  }

  Future<void> discardDraft(String id) async {
    if (!_ownsAccount) throw StateError('Session account changed');
    await store.deleteDraft(id);
    await _refresh();
  }

  Future<void> sync({bool force = false}) async {
    if (_syncing || !_ownsAccount || (!remote.enabled && _historyRestored)) {
      return;
    }
    _syncing = true;
    _emit();
    try {
      await load();
      final pending = remote.enabled
          ? _records.where((r) => r.state == SavedSessionState.pending).toList()
          : const <SavedTrainingSession>[];
      for (final record in pending) {
        if (!_ownsAccount) return;
        if (!force &&
            record.retryAfter != null &&
            now().isBefore(record.retryAfter!)) {
          continue;
        }
        final attempts = record.attempts + 1;
        final delay = min(900, 15 * pow(2, min(attempts - 1, 6)).toInt());
        final sending = record.withSync(
          state: SavedSessionState.pending,
          attempts: attempts,
          retryAfter: now().toUtc().add(Duration(seconds: delay)),
        );
        // Persist retry timing before the request; process death cannot create
        // an unbounded retry loop. The immutable session ID never changes.
        await store.save(sending);
        await _refresh();
        SavedTrainingSession response;
        try {
          await remote.submit(sending);
          response = sending.withSync(state: SavedSessionState.confirmed);
        } on TrainingSessionRejected {
          response = sending.withSync(
            state: SavedSessionState.rejected,
            error: 'El servidor no pudo aceptar esta sesión. El resultado sigue en este teléfono.',
          );
        } catch (_) {
          response = sending.withSync(
            state: SavedSessionState.pending,
            retryAfter: sending.retryAfter,
            error: 'No se pudo sincronizar. Reintentaremos más tarde.',
          );
        }
        if (!_ownsAccount) return;
        await store.save(response);
        await _refresh();
      }
      if (!_historyRestored && _ownsAccount) {
        await _restoreHistory();
      }
    } finally {
      _syncing = false;
      _emit();
    }
  }

  Future<void> _restoreHistory() async {
    final List<SavedTrainingSession> history;
    try {
      history = await remote.fetchHistory(store.ownerId);
    } catch (_) {
      // Keep opening offline and retry the download on the next sync.
      return;
    }
    final local = {
      for (final record in _records) record.result.sessionId: record,
    };
    var saved = false;
    try {
      for (final record in history) {
        if (!_ownsAccount) return;
        if (record.ownerId != store.ownerId ||
            record.state != SavedSessionState.confirmed) {
          continue;
        }
        final existing = local[record.result.sessionId];
        if (existing?.state == SavedSessionState.confirmed ||
            existing?.state == SavedSessionState.rejected) {
          continue;
        }
        if (existing?.state == SavedSessionState.pending &&
            jsonEncode(existing!.result.toJson()) !=
                jsonEncode(record.result.toJson())) {
          continue;
        }
        await store.save(record);
        saved = true;
      }
      _historyRestored = _ownsAccount;
    } finally {
      if (saved && _ownsAccount) await _refresh();
    }
  }

  void dispose() {
    if (_closed) return;
    _closed = true;
    _timer?.cancel();
    unawaited(_changes.close());
  }
}
