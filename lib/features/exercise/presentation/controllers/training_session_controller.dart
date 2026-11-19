import 'package:flutter/foundation.dart';

import '../../domain/models/training_session.dart';
import '../../domain/models/squat_observation.dart';
import '../../domain/services/squat_counter.dart';

enum TrainingPhase { preparation, active, recovering, paused, finished }

/// Session transitions independent of the camera, navigation and persistence.
/// Only a complete cycle from a posture source may call [recordValidRep].
class TrainingSessionController extends ChangeNotifier {
  TrainingSessionController({
    this.source = TrainingSource.camera,
    DateTime Function()? now,
    String Function()? createId,
  }) : _now = now ?? DateTime.now,
       _createId = createId ?? createTrainingSessionId;

  final TrainingSource source;
  final DateTime Function() _now;
  final String Function() _createId;
  final Stopwatch _clock = Stopwatch();
  final SquatCounter _counter = SquatCounter();
  String _feedback = 'Ponte de pie y mantén la postura inicial.';
  DateTime? _startedAt;
  String? _sessionId;
  TrainingSessionResult? _result;
  TrainingPhase _phase = TrainingPhase.preparation;
  bool _postureReady = false;
  int _reps = 0;
  SquatObservation? _lastUsable;

  TrainingPhase get phase => _phase;
  bool get postureReady => _postureReady;
  int get reps => _reps;
  String get feedback => _feedback;
  String? get sessionId => _sessionId;
  TrainingSessionResult? get result => _result;
  TrainingSessionResult? checkpoint() {
    if (_result != null) return _result;
    if (_startedAt == null || _sessionId == null) return null;
    return _snapshot();
  }

  SessionSyncStatus get syncStatus => SessionSyncStatus.notSaved;
  Duration get activeDuration => _clock.elapsed;
  bool get inProgress =>
      _phase != TrainingPhase.preparation && _phase != TrainingPhase.finished;

  void updatePosture({required bool ready}) {
    if (_phase == TrainingPhase.finished) return;
    var changed = _postureReady != ready;
    _postureReady = ready;
    if (!ready) {
      _counter.reset();
      _lastUsable = null;
    }
    if (!ready && _phase == TrainingPhase.active) {
      _clock.stop();
      _phase = TrainingPhase.recovering;
      changed = true;
    } else if (ready && _phase == TrainingPhase.recovering) {
      _clock.start();
      _phase = TrainingPhase.active;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void processObservation(SquatObservation observation) {
    if (_phase == TrainingPhase.finished || _phase == TrainingPhase.paused) {
      return;
    }
    final usable = SquatCounter.usable(observation);
    final previous = _lastUsable;
    if (kDebugMode && const bool.fromEnvironment('SQUAT_TRACE')) {
      debugPrint(
        '[squat] ${observation.timestamp.inMilliseconds}ms '
        '$phase/${_counter.phase.name} visible=${observation.readiness.bodyVisible} '
        'ready=${observation.readiness.initialPostureReady} usable=$usable '
        'left=${observation.leftKneeAngle.toStringAsFixed(1)} '
        'right=${observation.rightKneeAngle.toStringAsFixed(1)} '
        'hipHeight=${observation.hipHeight.toStringAsFixed(3)} '
        'gapMs=${previous == null ? null : (observation.timestamp - previous.timestamp).inMilliseconds} '
        'reps=$_reps',
      );
    }
    if (previous != null && observation.timestamp <= previous.timestamp) return;
    if (_phase == TrainingPhase.active) {
      final lost =
          previous != null &&
          observation.timestamp - previous.timestamp >
              SquatSessionRules.maximumFrameGap;
      if (lost) updatePosture(ready: false);
      if (!usable && !lost) {
        _counter.interruptStability();
        _setFeedback('Mantente dentro del encuadre.');
        return;
      }
    }
    if (_phase != TrainingPhase.active) {
      final ready = usable && observation.readiness.initialPostureReady;
      final recovering = _phase == TrainingPhase.recovering;
      if (ready) {
        _lastUsable = observation;
        if (recovering) _counter.arm(observation);
      }
      updatePosture(ready: ready);
      _setFeedback(
        _phase == TrainingPhase.active
            ? _counter.instruction
            : observation.readiness.instruction,
      );
      return;
    }
    _lastUsable = observation;
    final counted = _counter.observe(observation);
    _setFeedback(_counter.instruction);
    if (counted) recordValidRep();
  }

  void _setFeedback(String value) {
    if (_feedback == value) return;
    _feedback = value;
    notifyListeners();
  }

  void start() {
    if (_phase != TrainingPhase.preparation || !_postureReady) return;
    _sessionId = _createId();
    _startedAt = _now().toUtc();
    final prepared = _lastUsable;
    if (prepared != null) {
      _counter.arm(prepared);
    } else {
      _counter.reset();
    }
    _feedback = _counter.instruction;
    _phase = TrainingPhase.active;
    _clock.start();
    notifyListeners();
  }

  void recordValidRep() {
    if (_phase != TrainingPhase.active || !_postureReady) return;
    _reps++;
    notifyListeners();
  }

  void pause() {
    if (_phase != TrainingPhase.active && _phase != TrainingPhase.recovering) {
      return;
    }
    _clock.stop();
    _postureReady = false;
    _lastUsable = null;
    _counter.reset();
    _phase = TrainingPhase.paused;
    notifyListeners();
  }

  void resume() {
    if (_phase != TrainingPhase.paused) return;
    _postureReady = false;
    _lastUsable = null;
    _counter.reset();
    _phase = TrainingPhase.recovering;
    notifyListeners();
  }

  void finish() {
    if (!inProgress) return;
    _clock.stop();
    _counter.reset();
    _result = _snapshot();
    _phase = TrainingPhase.finished;
    notifyListeners();
  }

  void prepareAnotherSeries() {
    if (_phase != TrainingPhase.finished) return;
    _clock.reset();
    _startedAt = null;
    _sessionId = null;
    _result = null;
    _postureReady = false;
    _lastUsable = null;
    _reps = 0;
    _feedback = _counter.instruction;
    _phase = TrainingPhase.preparation;
    notifyListeners();
  }

  TrainingSessionResult _snapshot() {
    final startedAt = _startedAt!;
    final duration = _clock.elapsed;
    // Wall-clock adjustments must not invalidate monotonic active duration.
    final earliestEnd = startedAt.add(duration);
    final now = _now().toUtc();
    return TrainingSessionResult(
      sessionId: _sessionId!,
      exerciseId: SquatSessionRules.exerciseId,
      rulesVersion: SquatSessionRules.version,
      source: source,
      startedAtUtc: startedAt,
      endedAtUtc: now.isBefore(earliestEnd) ? earliestEnd : now,
      activeDuration: duration,
      validReps: _reps,
    );
  }

  @override
  void dispose() {
    _clock.stop();
    super.dispose();
  }
}
