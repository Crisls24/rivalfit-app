/// Liga de hasta [maxMembers] usuarios. La capacidad la valida el trigger
/// `trg_league_capacity` en el backend (PRD RF-7).
class League {
  final String id;
  final String name;
  final String emoji;
  final String iconText;
  final String? photoUrl;
  final String? socialBet;
  final String code;
  final String ownerId;
  final int maxMembers;
  final int memberCount;
  final DateTime createdAt;

  const League({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    required this.maxMembers,
    required this.createdAt,
    this.emoji = '🏆',
    this.iconText = 'podium',
    this.photoUrl,
    this.socialBet,
    this.memberCount = 0,
  });
}

/// Fila del ranking de una liga (weekly_points de la semana en curso).
class LeagueMember {
  final String userId;
  final String displayName;
  final String? alias;
  final String? photoUrl;
  final int weeklyPoints;
  final int? position;
  final int? legReps;
  final int? chestArmReps;
  final LeagueSession? lastSession;
  final DailyAward? dailyAward;

  String get name =>
      alias?.trim().isNotEmpty == true ? alias!.trim() : displayName;
  final DateTime joinedAt;

  const LeagueMember({
    required this.userId,
    required this.displayName,
    required this.weeklyPoints,
    this.position,
    this.legReps,
    this.chestArmReps,
    this.lastSession,
    this.dailyAward,
    required this.joinedAt,
    this.alias,
    this.photoUrl,
  });
}

typedef LeagueSession = ({String exercise, int reps, DateTime endedAt});
typedef DailyAward = ({int reps, DateTime day, bool closed});

/// Older rankings return ordered scores without explicit positions.
int leaguePosition(List<LeagueMember> ranking, int index) =>
    ranking[index].position ??
    (ranking.indexWhere((m) => m.weeklyPoints == ranking[index].weeklyPoints) +
        1);

/// Resultado de busqueda por @alias para invitar amigos.
class UserSearchResult {
  final String id;
  final String displayName;
  final String? alias;
  final String? photoUrl;

  const UserSearchResult({
    required this.id,
    required this.displayName,
    this.alias,
    this.photoUrl,
  });
}
