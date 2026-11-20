import 'dart:math' as math;

import '../models/posture_readiness.dart';
import '../models/training_observation.dart';
import '../models/training_session.dart';

enum PushUpSide { left, right }

enum PushUpPhase { waitingForTop, extended, lowering, bottom }

class PushUpObservation extends TrainingObservation {
  const PushUpObservation({
    required super.timestamp,
    required super.readiness,
    required this.side,
    required this.elbowAngle,
    required this.shoulderHeight,
    required this.aligned,
  });

  final PushUpSide? side;
  final double elbowAngle;
  final double shoulderHeight;
  final bool aligned;
}

/// Landmarks are shoulder, elbow, wrist, hip and ankle, in that order.
/// One side stays selected while it remains visible from the diagonal view.
class PushUpPoseGate {
  PushUpSide? _side;
  Duration? _stableSince;

  void reset() {
    _side = null;
    _stableSince = null;
  }

  PushUpObservation evaluate({
    required List<BodyPoint> left,
    required List<BodyPoint> right,
    required Duration timestamp,
    required double aspectRatio,
  }) {
    bool visible(List<BodyPoint> points) =>
        points.length == 5 &&
        points.every(
          (p) =>
              p.confidence >= 0.65 &&
              p.x > 0.03 &&
              p.x < 0.97 &&
              p.y > 0.03 &&
              p.y < 0.97,
        );
    final leftVisible = visible(left);
    final rightVisible = visible(right);
    final side = switch (_side) {
      PushUpSide.left when leftVisible => PushUpSide.left,
      PushUpSide.right when rightVisible => PushUpSide.right,
      _ when leftVisible => PushUpSide.left,
      _ when rightVisible => PushUpSide.right,
      _ => null,
    };
    if (side == null) {
      reset();
      return PushUpObservation(
        timestamp: timestamp,
        readiness: const PostureReadiness(
          false,
          false,
          'Mira hacia el celular y encuadra manos, cadera y pies.',
        ),
        side: null,
        elbowAngle: double.nan,
        shoulderHeight: double.nan,
        aligned: false,
      );
    }
    if (_side != side) _stableSince = null;
    _side = side;
    final points = side == PushUpSide.left ? left : right;
    final [shoulder, elbow, wrist, hip, ankle] = points;
    final horizontal = ((shoulder.x - ankle.x) * aspectRatio).abs();
    final vertical = (shoulder.y - ankle.y).abs();
    final length = math.sqrt(horizontal * horizontal + vertical * vertical);
    final elbowAngle = jointAngle([shoulder, elbow, wrist], aspectRatio);
    final shoulderHeight = (wrist.y - shoulder.y) / length;
    final aligned =
        horizontal >= 0.06 &&
        vertical <= 0.85 * horizontal &&
        jointAngle([shoulder, hip, ankle], aspectRatio) >= 155 &&
        shoulderHeight.isFinite &&
        shoulderHeight > 0;
    final extended = elbowAngle >= PushUpCounter.extendedAngle;
    if (aligned && extended) {
      _stableSince ??= timestamp;
    } else {
      _stableSince = null;
    }
    final ready =
        _stableSince != null &&
        timestamp - _stableSince! >= const Duration(milliseconds: 700);
    return PushUpObservation(
      timestamp: timestamp,
      readiness: PostureReadiness(
        true,
        ready,
        ready
            ? 'Postura lista'
            : !aligned
            ? 'Coloca el celular al frente, un poco a un lado. Alinea hombros, cadera y tobillos.'
            : 'Extiende los brazos y mantén la posición.',
      ),
      side: side,
      elbowAngle: elbowAngle,
      shoulderHeight: shoulderHeight,
      aligned: aligned,
    );
  }
}

class PushUpCounter implements TrainingRepCounter {
  // Initial projected thresholds. Calibrate on a real diagonal camera view.
  static const extendedAngle = 155.0;
  static const _descentAngle = 145.0;
  static const _bottomAngle = 100.0;
  PushUpPhase _phase = PushUpPhase.waitingForTop;
  PushUpSide? _side;
  Duration? _lastSample;
  Duration? _cycleStarted;
  Duration? _stableSince;
  double? _topHeight;
  bool _shortRep = false;

  @override
  PushUpPhase get phase => _phase;

  @override
  String get instruction => switch (_phase) {
    PushUpPhase.waitingForTop => 'Extiende los brazos en posición de plancha.',
    PushUpPhase.extended when _shortRep => 'En la siguiente, baja un poco más.',
    PushUpPhase.extended => 'Baja el pecho.',
    PushUpPhase.lowering => 'Completa el descenso.',
    PushUpPhase.bottom => 'Sube y extiende los brazos.',
  };

  @override
  bool isUsable(TrainingObservation sample) =>
      sample is PushUpObservation &&
      sample.readiness.bodyVisible &&
      sample.aligned &&
      sample.side != null &&
      (_side == null || _side == sample.side) &&
      sample.elbowAngle.isFinite &&
      sample.elbowAngle > 0 &&
      sample.elbowAngle <= 180 &&
      sample.shoulderHeight.isFinite &&
      sample.shoulderHeight > 0;

  @override
  void arm(PushUpObservation sample) {
    reset();
    if (!sample.readiness.initialPostureReady || !isUsable(sample)) return;
    _phase = PushUpPhase.extended;
    _side = sample.side;
    _topHeight = sample.shoulderHeight;
    _lastSample = sample.timestamp;
  }

  @override
  void interruptStability() => _stableSince = null;

  @override
  void reset() {
    _phase = PushUpPhase.waitingForTop;
    _side = null;
    _lastSample = null;
    _cycleStarted = null;
    _stableSince = null;
    _topHeight = null;
    _shortRep = false;
  }

  @override
  bool observe(PushUpObservation sample) {
    final now = sample.timestamp;
    final last = _lastSample;
    if (last != null && now <= last) return false;
    if (!isUsable(sample) ||
        (last != null && now - last > SquatSessionRules.maximumFrameGap) ||
        (_cycleStarted != null &&
            now - _cycleStarted! > SquatSessionRules.maximumCycle)) {
      reset();
      return false;
    }
    _lastSample = now;
    if (_phase == PushUpPhase.waitingForTop) {
      if (sample.readiness.initialPostureReady) arm(sample);
      return false;
    }
    final topHeight = _topHeight!;
    final atTop =
        sample.elbowAngle >= extendedAngle &&
        (sample.shoulderHeight - topHeight).abs() <= topHeight * 0.20;
    final atBottom =
        sample.elbowAngle <= _bottomAngle &&
        sample.shoulderHeight <= topHeight * 0.70;
    switch (_phase) {
      case PushUpPhase.waitingForTop:
        return false;
      case PushUpPhase.extended:
        if (sample.elbowAngle < _descentAngle) {
          _phase = PushUpPhase.lowering;
          _cycleStarted = now;
          _stableSince = atBottom ? now : null;
          _shortRep = false;
        }
      case PushUpPhase.lowering:
        if (atTop) {
          _phase = PushUpPhase.extended;
          _cycleStarted = null;
          _stableSince = null;
          _shortRep = true;
        } else if (atBottom) {
          _stableSince ??= now;
          if (now - _stableSince! >= SquatSessionRules.depthStability) {
            _phase = PushUpPhase.bottom;
            _stableSince = null;
          }
        } else {
          _stableSince = null;
        }
      case PushUpPhase.bottom:
        if (!atTop) {
          _stableSince = null;
          return false;
        }
        _stableSince ??= now;
        if (now - _stableSince! >= SquatSessionRules.topStability &&
            now - _cycleStarted! >= SquatSessionRules.minimumCycle) {
          _phase = PushUpPhase.extended;
          _cycleStarted = null;
          _stableSince = null;
          return true;
        }
    }
    return false;
  }
}
