enum AuthProviderType { google, facebook, apple, email }

enum FitnessLevel {
  beginner,
  intermediate,
  advanced;

  String get storageValue => switch (this) {
        FitnessLevel.beginner => 'beginner',
        FitnessLevel.intermediate => 'intermediate',
        FitnessLevel.advanced => 'advanced',
      };

  String get label => switch (this) {
        FitnessLevel.beginner => 'Novato',
        FitnessLevel.intermediate => 'Intermedio',
        FitnessLevel.advanced => 'Avanzado',
      };

  String get description => switch (this) {
        FitnessLevel.beginner => 'Estoy empezando',
        FitnessLevel.intermediate => 'Entreno con constancia',
        FitnessLevel.advanced => 'Voy por mi mejor versión',
      };

  static FitnessLevel? fromStorage(String? value) => switch (value) {
        'beginner' => FitnessLevel.beginner,
        'intermediate' => FitnessLevel.intermediate,
        'advanced' => FitnessLevel.advanced,
        _ => null,
      };
}

class User {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final AuthProviderType authProvider;
  final int level;
  final int totalReps;
  final int currentStreak;
  final int longestStreak;
  final List<dynamic> badges;
  final DateTime createdAt;
  final bool isProfileComplete;
  final FitnessLevel? fitnessLevel;
  final double? weightKg;
  final int? heightCm;

  const User({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.authProvider,
    this.level = 0,
    this.totalReps = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.badges = const [],
    required this.createdAt,
    this.isProfileComplete = false,
    this.fitnessLevel,
    this.weightKg,
    this.heightCm,
  });
}
