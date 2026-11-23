import 'dart:math';

enum TrainingSource { camera, simulation, stepSensor }

enum SessionSyncStatus { notSaved, pending, confirmed, rejected }

enum TrainingMovement {
  squat(SquatSessionRules.exerciseId, SquatSessionRules.version, 'Sentadillas'),
  pushUp('lagartijas', 'lagartijas-v1', 'Lagartijas'),
  crunch('abdominales', 'abdominales-v1', 'Abdominales'),
  plank('plancha', 'plancha-v1', 'Plancha');

  const TrainingMovement(this.id, this.rulesVersion, this.label);

  final String id;
  final String rulesVersion;
  final String label;

  static TrainingMovement? forId(String id) =>
      values.where((movement) => movement.id == id).firstOrNull;
}

/// Versioned rules shared by the session flow and future persistence adapter.
/// Thresholds for interpreting posture belong to the calibrated counter.
abstract final class SquatSessionRules {
  static const exerciseId = 'sentadillas';
  static const version = 'sentadillas-v1';
  static const globalRepsPerRep = 1;
  static const legRepsPerRep = 1;
  static const leaguePointsPerRep = 1;
  // Initial projected-angle thresholds; calibrate on device before release.
  static const standingAngle = 160.0;
  static const descentAngle = 145.0;
  static const depthAngle = 105.0;
  static const maxLegAngleDifference = 35.0;
  static const minimumHipDrop = 0.20;
  static const maximumStandingHeightDifference = 0.12;
  static const topStability = Duration(milliseconds: 250);
  static const depthStability = Duration(milliseconds: 150);
  static const minimumCycle = Duration(milliseconds: 600);
  static const maximumCycle = Duration(seconds: 15);
  static const maximumFrameGap = Duration(milliseconds: 700);
}

/// Immutable local result. A camera result is not a server confirmation.
/// Simulation results must never be sent for competitive accreditation.
class TrainingSessionResult {
  final String sessionId;
  final String exerciseId;
  final String rulesVersion;
  final TrainingSource source;
  final DateTime startedAtUtc;
  final DateTime endedAtUtc;
  final Duration activeDuration;
  final int validReps;
  final Duration holdDuration;
  final int steps;

  TrainingSessionResult({
    required this.sessionId,
    required this.exerciseId,
    required this.rulesVersion,
    required this.source,
    required DateTime startedAtUtc,
    required DateTime endedAtUtc,
    required this.activeDuration,
    required this.validReps,
    this.holdDuration = Duration.zero,
    this.steps = 0,
  }) : startedAtUtc = startedAtUtc.toUtc(),
       endedAtUtc = endedAtUtc.toUtc() {
    if (sessionId.isEmpty || exerciseId.isEmpty || rulesVersion.isEmpty) {
      throw ArgumentError('Session identity and rules are required.');
    }
    if (validReps < 0 ||
        steps < 0 ||
        holdDuration.isNegative ||
        holdDuration > activeDuration ||
        activeDuration.isNegative ||
        this.endedAtUtc.isBefore(this.startedAtUtc) ||
        activeDuration > this.endedAtUtc.difference(this.startedAtUtc)) {
      throw ArgumentError('Inconsistent session result.');
    }
  }

  bool get eligibleForSubmission =>
      source == TrainingSource.camera &&
      validReps > 0 &&
      (exerciseId == TrainingMovement.squat.id ||
          exerciseId == TrainingMovement.pushUp.id);

  bool get eligibleForLocalHistory =>
      !eligibleForSubmission &&
      switch (source) {
        TrainingSource.camera =>
          (exerciseId == TrainingMovement.crunch.id && validReps > 0) ||
              (exerciseId == TrainingMovement.plank.id &&
                  holdDuration.inSeconds > 0),
        TrainingSource.stepSensor => exerciseId == 'cardio' && steps > 0,
        TrainingSource.simulation => false,
      };

  String get measurementLabel {
    if (exerciseId == TrainingMovement.plank.id) {
      return '${holdDuration.inSeconds} s';
    }
    if (exerciseId == 'cardio') {
      return '$steps ${steps == 1 ? 'paso' : 'pasos'}';
    }
    return '$validReps ${validReps == 1 ? 'repetición' : 'repeticiones'}';
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'exercise_id': exerciseId,
    'rules_version': rulesVersion,
    'source': source.name,
    'started_at': startedAtUtc.toIso8601String(),
    'ended_at': endedAtUtc.toIso8601String(),
    'active_duration_us': activeDuration.inMicroseconds,
    'valid_reps': validReps,
    if (holdDuration > Duration.zero)
      'hold_duration_us': holdDuration.inMicroseconds,
    if (steps > 0) 'steps': steps,
  };

  factory TrainingSessionResult.fromJson(
    Map<String, dynamic> json,
  ) => TrainingSessionResult(
    sessionId: json['session_id'] as String,
    exerciseId: json['exercise_id'] as String,
    rulesVersion: json['rules_version'] as String,
    source: TrainingSource.values.byName(json['source'] as String),
    startedAtUtc: DateTime.parse(json['started_at'] as String),
    endedAtUtc: DateTime.parse(json['ended_at'] as String),
    activeDuration: Duration(microseconds: json['active_duration_us'] as int),
    validReps: json['valid_reps'] as int,
    holdDuration: Duration(microseconds: json['hold_duration_us'] as int? ?? 0),
    steps: json['steps'] as int? ?? 0,
  );
}

/// UUID v4 generated once on start, retained for all future retries.
String createTrainingSessionId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
