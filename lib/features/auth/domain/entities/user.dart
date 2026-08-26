enum AuthProviderType { google, facebook, apple, email }

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
  });
}
