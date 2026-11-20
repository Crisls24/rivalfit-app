import 'posture_readiness.dart';

class TrainingObservation {
  const TrainingObservation({required this.timestamp, required this.readiness});

  final Duration timestamp;
  final PostureReadiness readiness;
}

abstract interface class TrainingRepCounter {
  Enum get phase;
  String get instruction;
  bool isUsable(TrainingObservation sample);
  void arm(covariant TrainingObservation sample);
  bool observe(covariant TrainingObservation sample);
  void interruptStability();
  void reset();
}
