import 'dart:typed_data';

import 'package:rivalfit/core/error/failures.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';
import 'package:rivalfit/features/league/domain/repositories/league_repository.dart';

class DemoLeagueRepository implements LeagueRepository {
  DemoLeagueRepository(this._currentUserId);

  final String? Function() _currentUserId;
  bool _joined = true;
  final DateTime _createdAt = DateTime.now().subtract(const Duration(days: 6));

  String get _userId {
    final id = _currentUserId();
    return id == null || id.isEmpty ? 'demo-me' : id;
  }

  League get _league => League(
    id: 'demo-league',
    name: 'Escuadra Rival',
    code: 'DEMO42',
    ownerId: _userId,
    maxMembers: 10,
    memberCount: 5,
    createdAt: _createdAt,
    emoji: '🔥',
    socialBet: 'Reto semanal: 60 repeticiones al día',
  );

  List<LeagueMember> get _ranking {
    final now = DateTime.now();
    return [
      LeagueMember(
        userId: _userId,
        displayName: 'Cris Losada',
        alias: 'cris',
        weeklyPoints: 320,
        position: 1,
        legReps: 54,
        chestArmReps: 18,
        lastSession: (
          exercise: 'sentadillas',
          reps: 30,
          endedAt: now.subtract(const Duration(minutes: 12)),
        ),
        dailyAward: (reps: 42, day: now, closed: false),
        joinedAt: _createdAt,
      ),
      LeagueMember(
        userId: 'demo-kevin',
        displayName: 'Kevin Ruiz',
        alias: 'kevinr',
        weeklyPoints: 285,
        position: 2,
        legReps: 40,
        chestArmReps: 8,
        lastSession: (
          exercise: 'lagartijas',
          reps: 22,
          endedAt: now.subtract(const Duration(hours: 2)),
        ),
        joinedAt: _createdAt.add(const Duration(days: 1)),
      ),
      LeagueMember(
        userId: 'demo-mari',
        displayName: 'Mari Torres',
        alias: 'marit',
        weeklyPoints: 240,
        position: 3,
        legReps: 12,
        chestArmReps: 34,
        lastSession: (
          exercise: 'lagartijas',
          reps: 28,
          endedAt: now.subtract(const Duration(hours: 5)),
        ),
        joinedAt: _createdAt.add(const Duration(days: 2)),
      ),
      LeagueMember(
        userId: 'demo-diego',
        displayName: 'Diego Pérez',
        alias: 'diegop',
        weeklyPoints: 180,
        position: 4,
        legReps: 18,
        chestArmReps: 6,
        lastSession: (
          exercise: 'sentadillas',
          reps: 20,
          endedAt: now.subtract(const Duration(days: 1)),
        ),
        joinedAt: _createdAt.add(const Duration(days: 3)),
      ),
      LeagueMember(
        userId: 'demo-ana',
        displayName: 'Ana Soto',
        alias: 'anas',
        weeklyPoints: 95,
        position: 5,
        legReps: 0,
        chestArmReps: 10,
        lastSession: (
          exercise: 'lagartijas',
          reps: 12,
          endedAt: now.subtract(const Duration(days: 2)),
        ),
        joinedAt: _createdAt.add(const Duration(days: 4)),
      ),
    ];
  }

  @override
  Future<({League? league, Failure? error})> getMyLeague() async =>
      (league: _joined ? _league : null, error: null);

  @override
  Future<({League? league, Failure? error})> findByCode(String code) async => (
    league: code.trim().toUpperCase() == _league.code ? _league : null,
    error: null,
  );

  @override
  Future<({List<LeagueMember> items, Failure? error})> getRanking(
    String leagueId,
  ) async => (
    items: _joined && leagueId == _league.id ? _ranking : <LeagueMember>[],
    error: null,
  );

  @override
  Future<({List<UserSearchResult> items, Failure? error})> searchByAlias(
    String query,
  ) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return (items: <UserSearchResult>[], error: null);
    return (
      items: _ranking
          .where((member) => member.userId != _userId)
          .where(
            (member) =>
                '${member.name} ${member.displayName}'
                    .toLowerCase()
                    .contains(q),
          )
          .map(
            (member) => UserSearchResult(
              id: member.userId,
              displayName: member.displayName,
              alias: member.alias,
              photoUrl: member.photoUrl,
            ),
          )
          .toList(),
      error: null,
    );
  }

  @override
  Future<({League? league, Failure? error})> createLeague(
    String name, {
    String emoji = '🏆',
    String? socialBet,
  }) async {
    _joined = true;
    return (league: _league, error: null);
  }

  @override
  Future<Failure?> uploadLeaguePhoto({
    required String leagueId,
    required Uint8List bytes,
    required String fileName,
  }) async => null;

  @override
  Future<({League? league, Failure? error})> join(String code) async {
    _joined = true;
    return (league: _league, error: null);
  }

  @override
  Future<Failure?> leave(String leagueId) async {
    _joined = false;
    return null;
  }
}
