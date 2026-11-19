import 'posture_readiness.dart';

/// One local detector result. Does not contain images or remote payloads.
class SquatObservation {
  final Duration timestamp;
  final PostureReadiness readiness;
  final double leftKneeAngle;
  final double rightKneeAngle;

  /// Vertical distance from the midpoint of the ankles to the hips, in
  /// fractions of the image height.
  final double hipHeight;

  const SquatObservation({
    required this.timestamp,
    required this.readiness,
    required this.leftKneeAngle,
    required this.rightKneeAngle,
    required this.hipHeight,
  });
}
