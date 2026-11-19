import '../models/squat_observation.dart';
import '../models/training_session.dart';

enum SquatPhase { waitingForStart, standing, descending, depthReached }

/// Conservative initial thresholds, pending device calibration. This validates
/// a visible movement cycle, not complete exercise technique or identity.
class SquatCounter {
  SquatPhase _phase = SquatPhase.waitingForStart;
  Duration? _lastSample;
  Duration? _topSince;
  Duration? _bottomSince;
  Duration? _cycleStarted;
  double? _standingHipHeight;
  bool _missedDepth = false;

  SquatPhase get phase => _phase;

  String get instruction => switch (_phase) {
    SquatPhase.waitingForStart => 'Ponte de pie y mantén la postura inicial.',
    SquatPhase.standing when _missedDepth =>
      'En la siguiente, baja un poco más.',
    SquatPhase.standing => 'Baja despacio.',
    SquatPhase.descending => 'Completa el descenso a tu ritmo.',
    SquatPhase.depthReached => 'Vuelve a la postura inicial.',
  };

  void reset() {
    _phase = SquatPhase.waitingForStart;
    _lastSample = null;
    _topSince = null;
    _bottomSince = null;
    _cycleStarted = null;
    _standingHipHeight = null;
    _missedDepth = false;
  }

  void arm(SquatObservation sample) {
    reset();
    if (!sample.readiness.initialPostureReady || !usable(sample)) return;
    _lastSample = sample.timestamp;
    _standingHipHeight = sample.hipHeight;
    _phase = SquatPhase.standing;
  }

  static bool usable(SquatObservation sample) {
    final left = sample.leftKneeAngle;
    final right = sample.rightKneeAngle;
    return sample.readiness.bodyVisible &&
        sample.hipHeight.isFinite &&
        sample.hipHeight > 0 &&
        left.isFinite &&
        right.isFinite &&
        left >= 0 &&
        right >= 0 &&
        left <= 180 &&
        right <= 180 &&
        (left - right).abs() <= SquatSessionRules.maxLegAngleDifference;
  }

  void interruptStability() {
    _topSince = null;
    _bottomSince = null;
  }

  /// Returns true exactly once for a complete, continuous cycle.
  bool observe(SquatObservation sample) {
    final time = sample.timestamp;
    final left = sample.leftKneeAngle;
    final right = sample.rightKneeAngle;
    if (_lastSample != null && time <= _lastSample!) return false;
    final gap =
        _lastSample != null &&
        time - _lastSample! > SquatSessionRules.maximumFrameGap;
    if (gap) reset();
    _lastSample = time;
    if (!usable(sample)) {
      reset();
      return false;
    }
    if (_cycleStarted != null &&
        time - _cycleStarted! > SquatSessionRules.maximumCycle) {
      reset();
      _lastSample = time;
    }
    final standingHeight = _standingHipHeight;
    final hipDrop = standingHeight == null
        ? 0.0
        : (standingHeight - sample.hipHeight) / standingHeight;
    final legsExtended =
        left >= SquatSessionRules.standingAngle &&
        right >= SquatSessionRules.standingAngle;
    final standing =
        legsExtended &&
        hipDrop.abs() <= SquatSessionRules.maximumStandingHeightDifference;
    final deep =
        left <= SquatSessionRules.depthAngle &&
        right <= SquatSessionRules.depthAngle &&
        hipDrop >= SquatSessionRules.minimumHipDrop;
    switch (_phase) {
      case SquatPhase.waitingForStart:
        if (!standing) {
          _topSince = null;
          return false;
        }
        _topSince ??= time;
        if (time - _topSince! >= SquatSessionRules.topStability) {
          _standingHipHeight = sample.hipHeight;
          _phase = SquatPhase.standing;
          _topSince = null;
        }
      case SquatPhase.standing:
        if (left < SquatSessionRules.descentAngle &&
            right < SquatSessionRules.descentAngle) {
          _phase = SquatPhase.descending;
          _missedDepth = false;
          _cycleStarted = time;
          _bottomSince = deep ? time : null;
        }
      case SquatPhase.descending:
        if (standing) {
          // A partial descent ends the attempt without counting.
          _phase = SquatPhase.standing;
          _cycleStarted = null;
          _bottomSince = null;
          _missedDepth = true;
        } else if (deep) {
          _bottomSince ??= time;
          if (time - _bottomSince! >= SquatSessionRules.depthStability) {
            _phase = SquatPhase.depthReached;
            _topSince = null;
          }
        } else {
          _bottomSince = null;
        }
      case SquatPhase.depthReached:
        if (!standing) {
          _topSince = null;
          return false;
        }
        _topSince ??= time;
        if (time - _topSince! >= SquatSessionRules.topStability &&
            time - _cycleStarted! >= SquatSessionRules.minimumCycle) {
          _phase = SquatPhase.standing;
          _cycleStarted = null;
          _topSince = null;
          _bottomSince = null;
          return true;
        }
    }
    return false;
  }
}
