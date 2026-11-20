import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/training_session.dart';
import '../../domain/models/squat_observation.dart';
import '../../domain/models/training_observation.dart';
import '../../domain/services/push_up_counter.dart';
import '../../domain/services/squat_counter.dart';

enum TrainingPhase { preparation, active, recovering, paused, finished }

/// Session transitions independent of the camera, navigation and persistence.
/// Only a complete cycle from a posture source may call [recordValidRep].
class TrainingSessionController extends ChangeNotifier {
  static const trackingLossLimit = Duration(seconds: 10);

  TrainingSessionController({
    this.source = TrainingSource.camera,
    this.movement = TrainingMovement.squat,
    DateTime Function()? now,
    String Function()? createId,
  }) : _now = now ?? DateTime.now,
       _createId = createId ?? createTrainingSessionId;

  final TrainingSource source;
  final TrainingMovement movement;
  final DateTime Function() _now;
  final String Function() _createId;
  final Stopwatch _clock = Stopwatch();
  late final TrainingRepCounter _counter = switch (movement) {
    TrainingMovement.squat => SquatCounter(),
    TrainingMovement.pushUp => PushUpCounter(),
  };
  late String _feedback = _counter.instruction;
  DateTime? _startedAt;
  String? _sessionId;
  TrainingSessionResult? _result;
  TrainingPhase _phase = TrainingPhase.preparation;
  bool _postureReady = false;
  int _reps = 0;
  TrainingObservation? _lastUsable;
  Timer? _trackingLossTimer;
  bool _endedAfterTrackingLoss = false;

  TrainingPhase get phase => _phase;
  bool get postureReady => _postureReady;
  int get reps => _reps;
  String get feedback => _feedback;
  String? get sessionId => _sessionId;
  TrainingSessionResult? get result => _result;
  bool get endedAfterTrackingLoss => _endedAfterTrackingLoss;
  TrainingSessionResult? checkpoint() {
    if (_result != null) return _result;
    if (_startedAt == null || _sessionId == null) return null;
    return _snapshot();
  }

  SessionSyncStatus get syncStatus => SessionSyncStatus.notSaved;
  Duration get activeDuration => _clock.elapsed;
  bool get inProgress =>
      _phase != TrainingPhase.preparation && _phase != TrainingPhase.finished;

  void updatePosture({required bool ready}) => _updatePosture(ready);

  void _updatePosture(bool ready, {Duration trackingGap = Duration.zero}) {
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
      _feedback = 'Fuera de cuadro';
      _watchTrackingLoss(elapsed: trackingGap);
      if (_phase == TrainingPhase.finished) return;
      changed = true;
    } else if (ready && _phase == TrainingPhase.recovering) {
      _cancelTrackingTimeout();
      _clock.start();
      _phase = TrainingPhase.active;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void processObservation(TrainingObservation observation) {
    if (_phase == TrainingPhase.finished || _phase == TrainingPhase.paused) {
      return;
    }
    final usable = _counter.isUsable(observation);
    final previous = _lastUsable;
    if (kDebugMode && const bool.fromEnvironment('SQUAT_TRACE')) {
      final details = switch (observation) {
        SquatObservation(
          :final leftKneeAngle,
          :final rightKneeAngle,
          :final hipHeight,
        ) =>
          'left=${leftKneeAngle.toStringAsFixed(1)} right=${rightKneeAngle.toStringAsFixed(1)} hipHeight=${hipHeight.toStringAsFixed(3)} ',
        PushUpObservation(
          :final elbowAngle,
          :final shoulderHeight,
          :final side,
          :final aligned,
        ) =>
          'side=${side?.name} elbow=${elbowAngle.toStringAsFixed(1)} height=${shoulderHeight.toStringAsFixed(3)} aligned=$aligned ',
        _ => '',
      };
      debugPrint(
        '[${movement.name.toLowerCase()}] ${observation.timestamp.inMilliseconds}ms '
        '$phase/${_counter.phase.name} visible=${observation.readiness.bodyVisible} '
        'ready=${observation.readiness.initialPostureReady} usable=$usable '
        '$details'
        'gapMs=${previous == null ? null : (observation.timestamp - previous.timestamp).inMilliseconds} '
        'reps=$_reps',
      );
    }
    if (previous != null && observation.timestamp <= previous.timestamp) return;
    final gap = previous == null
        ? Duration.zero
        : observation.timestamp - previous.timestamp;
    if (_phase == TrainingPhase.active) {
      final lost =
          gap > SquatSessionRules.maximumFrameGap ||
          (previous == null && !usable);
      if (lost) {
        _updatePosture(false, trackingGap: gap);
        if (_phase == TrainingPhase.finished) return;
      }
      if (!usable && !lost) {
        if (observation is PushUpObservation &&
            observation.readiness.bodyVisible &&
            !observation.aligned) {
          _counter.reset();
        } else {
          _counter.interruptStability();
        }
        _setFeedback(_trackingInstruction(observation));
        return;
      }
    }
    if (_phase != TrainingPhase.active) {
      final ready = usable && observation.readiness.initialPostureReady;
      final recovering = _phase == TrainingPhase.recovering;
      if (recovering && !usable) {
        _watchTrackingLoss(elapsed: gap);
        if (_phase != TrainingPhase.finished) {
          _setFeedback(_trackingInstruction(observation));
        }
        return;
      }
      if (recovering) {
        _cancelTrackingTimeout();
        _lastUsable = observation;
        if (!ready) {
          _setFeedback(observation.readiness.instruction);
          return;
        }
        _counter.arm(observation);
      }
      if (ready) {
        _lastUsable = observation;
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

  String _trackingInstruction(TrainingObservation observation) =>
      observation.readiness.bodyVisible
      ? 'Ajusta tu posición'
      : 'Fuera de cuadro';

  void _watchTrackingLoss({required Duration elapsed}) {
    if (_trackingLossTimer != null) return;
    final remaining = trackingLossLimit - elapsed;
    if (remaining <= Duration.zero) {
      _finishAfterTrackingLoss();
    } else {
      _trackingLossTimer = Timer(remaining, _finishAfterTrackingLoss);
    }
  }

  void _cancelTrackingTimeout() {
    _trackingLossTimer?.cancel();
    _trackingLossTimer = null;
  }

  void _finishAfterTrackingLoss() {
    if (_phase != TrainingPhase.recovering) return;
    _endedAfterTrackingLoss = true;
    finish();
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
    _cancelTrackingTimeout();
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
    _feedback = _counter.instruction;
    _phase = TrainingPhase.recovering;
    notifyListeners();
  }

  void finish() {
    if (!inProgress) return;
    _cancelTrackingTimeout();
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
    _endedAfterTrackingLoss = false;
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
      exerciseId: movement.id,
      rulesVersion: movement.rulesVersion,
      source: source,
      startedAtUtc: startedAt,
      endedAtUtc: now.isBefore(earliestEnd) ? earliestEnd : now,
      activeDuration: duration,
      validReps: _reps,
    );
  }

  @override
  void dispose() {
    _cancelTrackingTimeout();
    _clock.stop();
    super.dispose();
  }
}
