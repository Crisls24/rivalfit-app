import 'dart:math' as math;

import 'training_session.dart';

class BodyPoint {
  final double x;
  final double y;
  final double confidence;
  const BodyPoint(this.x, this.y, this.confidence);
}

class PostureReadiness {
  final bool bodyVisible;
  final bool initialPostureReady;
  final String instruction;
  const PostureReadiness(
    this.bodyVisible,
    this.initialPostureReady,
    this.instruction,
  );
}

/// Readiness only: these thresholds do not validate or count squats.
class PostureReadinessGate {
  Duration? _stableSince;

  void reset() => _stableSince = null;

  PostureReadiness evaluate({
    required List<BodyPoint> leftLeg,
    required List<BodyPoint> rightLeg,
    required List<BodyPoint> shoulders,
    required Duration timestamp,
    double aspectRatio = 1,
  }) {
    final points = [...leftLeg, ...rightLeg, ...shoulders];
    final visible =
        leftLeg.length == 3 &&
        rightLeg.length == 3 &&
        shoulders.length == 2 &&
        points.every(
          (p) =>
              p.confidence >= 0.65 &&
              p.x.isFinite &&
              p.y.isFinite &&
              p.x > 0.03 &&
              p.x < 0.97 &&
              p.y > 0.03 &&
              p.y < 0.97,
        );
    if (!visible) {
      reset();
      return const PostureReadiness(
        false,
        false,
        'Aléjate hasta que se vean hombros, cadera, rodillas y tobillos.',
      );
    }
    final leftAngle = jointAngle(leftLeg, aspectRatio);
    final rightAngle = jointAngle(rightLeg, aspectRatio);
    if (!leftAngle.isFinite ||
        !rightAngle.isFinite ||
        leftAngle < SquatSessionRules.standingAngle ||
        rightAngle < SquatSessionRules.standingAngle) {
      reset();
      return const PostureReadiness(
        true,
        false,
        'Ponte de pie para preparar la postura inicial.',
      );
    }
    _stableSince ??= timestamp;
    final ready =
        timestamp - _stableSince! >= const Duration(milliseconds: 700);
    return PostureReadiness(
      true,
      ready,
      ready ? 'Postura lista' : 'Mantén la postura un momento.',
    );
  }
}

/// Coordinates are normalized; aspect ratio restores metric proportions.
double jointAngle(List<BodyPoint> points, double aspectRatio) {
  if (points.length != 3 || !aspectRatio.isFinite || aspectRatio <= 0) {
    return double.nan;
  }
  final ax = (points[0].x - points[1].x) * aspectRatio;
  final ay = points[0].y - points[1].y;
  final bx = (points[2].x - points[1].x) * aspectRatio;
  final by = points[2].y - points[1].y;
  final length = math.sqrt((ax * ax + ay * ay) * (bx * bx + by * by));
  if (length <= 0) return 0;
  return math.acos(((ax * bx + ay * by) / length).clamp(-1.0, 1.0)) *
      180 /
      math.pi;
}
