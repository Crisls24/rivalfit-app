import 'dart:math' as math;

import '../models/posture_readiness.dart';
import '../models/training_observation.dart';

enum _CrunchPhase { bottom, lifting, top }

class CoreObservation extends TrainingObservation {
  const CoreObservation({
    required super.timestamp,
    required super.readiness,
    required this.side,
    this.aligned = false,
    this.torsoTilt = 0,
    this.torsoLength = 0,
    this.hipHeight = 0,
    this.kneeAngle = 0,
  });

  final int side;
  final bool aligned;
  final double torsoTilt;
  final double torsoLength;
  final double hipHeight;
  final double kneeAngle;
}

class CorePoseGate {
  Duration? _stableSince;
  int? _side;

  void reset() {
    _stableSince = null;
    _side = null;
  }

  CoreObservation evaluate({
    required List<BodyPoint> left,
    required List<BodyPoint> right,
    required Duration timestamp,
    required double aspectRatio,
    required bool plank,
  }) {
    bool visible(List<BodyPoint> points) =>
        points.length == (plank ? 5 : 4) &&
        points.every(
          (p) =>
              p.confidence >= 0.55 &&
              p.x > .02 &&
              p.x < .98 &&
              p.y > .02 &&
              p.y < .98,
        );

    final side = switch (_side) {
      0 when visible(left) => 0,
      1 when visible(right) => 1,
      _ when visible(left) => 0,
      _ when visible(right) => 1,
      _ => -1,
    };
    if (side == -1) {
      reset();
      return CoreObservation(
        timestamp: timestamp,
        readiness: const PostureReadiness(
          false,
          false,
          'Deja visibles el torso y los pies.',
        ),
        side: side,
      );
    }
    if (_side != side) _stableSince = null;
    _side = side;
    final points = side == 0 ? left : right;
    final shoulder = points[0];
    final hip = points[1];
    final ankle = points[3];
    final horizontal = (shoulder.x - hip.x).abs() * aspectRatio;
    final rise = hip.y - shoulder.y;
    final torsoLength = math.sqrt(horizontal * horizontal + rise * rise);
    final tilt = math.atan2(rise, horizontal) * 180 / math.pi;
    final knee = jointAngle([hip, points[2], ankle], aspectRatio);
    final elbow = points.last;
    final aligned =
        torsoLength >= .075 &&
        (plank
            ? tilt.abs() <= 30 &&
                  knee >= 145 &&
                  jointAngle([shoulder, hip, ankle], aspectRatio) >= 155 &&
                  elbow.y - shoulder.y >= .04 &&
                  (elbow.x - shoulder.x).abs() * aspectRatio < torsoLength * .8
            : knee >= 45 && knee <= 135 && ankle.y >= hip.y - .03);
    final starting = aligned && (plank || tilt.abs() <= 18);
    if (starting) {
      _stableSince ??= timestamp;
    } else {
      _stableSince = null;
    }
    final ready =
        _stableSince != null &&
        timestamp - _stableSince! >= const Duration(milliseconds: 500);
    return CoreObservation(
      timestamp: timestamp,
      readiness: PostureReadiness(
        true,
        ready,
        ready
            ? 'Postura lista'
            : plank
            ? 'Apoya los antebrazos y alinea hombros, cadera y pies.'
            : 'Recuéstate boca arriba con las rodillas flexionadas.',
      ),
      side: side,
      aligned: aligned,
      torsoTilt: tilt,
      torsoLength: torsoLength,
      hipHeight: hip.y,
      kneeAngle: knee,
    );
  }
}

class CoreCounter implements TrainingRepCounter {
  CoreCounter({required this.plank});

  final bool plank;
  _CrunchPhase _phase = _CrunchPhase.bottom;
  CoreObservation? _base;
  Duration? _liftStarted;

  @override
  Enum get phase => _phase;

  @override
  String get instruction => plank
      ? 'Mantén el cuerpo alineado'
      : _phase == _CrunchPhase.top
      ? 'Baja los hombros con control'
      : 'Eleva los hombros';

  @override
  bool isUsable(TrainingObservation observation) =>
      observation is CoreObservation && observation.aligned;

  @override
  void arm(CoreObservation observation) {
    reset();
    _base = observation;
  }

  @override
  bool observe(CoreObservation observation) {
    if (plank) return false;
    final base = _base;
    if (base == null ||
        base.side != observation.side ||
        (base.hipHeight - observation.hipHeight).abs() >
            base.torsoLength * .35 ||
        (base.kneeAngle - observation.kneeAngle).abs() > 30 ||
        (_liftStarted != null &&
            observation.timestamp - _liftStarted! >
                const Duration(seconds: 10))) {
      reset();
      if (observation.torsoTilt.abs() <= 18) arm(observation);
      return false;
    }
    final lift = observation.torsoTilt - base.torsoTilt;
    if (_phase == _CrunchPhase.bottom && lift >= 10) {
      _liftStarted = observation.timestamp;
      _phase = _CrunchPhase.lifting;
    }
    if (_phase == _CrunchPhase.lifting &&
        lift >= 21 &&
        observation.torsoTilt >= 24) {
      _phase = _CrunchPhase.top;
    }
    if (_phase != _CrunchPhase.bottom && lift <= 8) {
      final count =
          _phase == _CrunchPhase.top &&
          observation.timestamp - _liftStarted! >=
              const Duration(milliseconds: 420);
      arm(observation);
      return count;
    }
    return false;
  }

  @override
  void interruptStability() => reset();

  @override
  void reset() {
    _phase = _CrunchPhase.bottom;
    _base = null;
    _liftStarted = null;
  }
}
