import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:rivalfit/core/error/failures.dart';
import 'package:rivalfit/features/league/data/datasources/league_supabase_data_source.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';
import 'package:rivalfit/features/league/domain/repositories/league_repository.dart';

class LeagueRepositoryImpl implements LeagueRepository {
  final LeagueSupabaseDataSource dataSource;

  LeagueRepositoryImpl({required this.dataSource});

  @override
  Future<({League? league, Failure? error})> getMyLeague() async {
    try {
      final raw = await dataSource.getMyLeague();
      if (raw == null) return (league: null, error: null);
      return (league: _leagueFromMap(raw), error: null);
    } catch (e) {
      return (league: null, error: _friendly(e));
    }
  }

  @override
  Future<({League? league, Failure? error})> findByCode(String code) async {
    try {
      final raw = await dataSource.findByCode(code);
      if (raw == null) {
        return (
          league: null,
          error: const NotFoundFailure(
            message: 'El código no es válido o la liga ya no existe.',
          ),
        );
      }
      final count = await dataSource.memberCount(raw['id'] as String);
      return (league: _leagueFromMap(raw, memberCount: count), error: null);
    } catch (e) {
      return (league: null, error: _friendly(e));
    }
  }

  @override
  Future<({List<LeagueMember> items, Failure? error})> getRanking(
      String leagueId) async {
    try {
      final rows = await dataSource.getRanking(leagueId);
      return (
        items: rows.map(_memberFromMap).toList(),
        error: null,
      );
    } catch (e) {
      return (items: const <LeagueMember>[], error: _friendly(e));
    }
  }

  @override
  Future<({List<UserSearchResult> items, Failure? error})> searchByAlias(
      String query) async {
    try {
      final rows = await dataSource.searchByAlias(query);
      return (
        items: rows.map(_searchFromMap).toList(),
        error: null,
      );
    } catch (e) {
      return (items: const <UserSearchResult>[], error: _friendly(e));
    }
  }

  @override
  Future<({League? league, Failure? error})> createLeague(
    String name, {
    String emoji = '🏆',
  }) async {
    try {
      final raw = await dataSource.createLeague(name, emoji: emoji);
      return (league: _leagueFromMap(raw), error: null);
    } catch (e) {
      return (league: null, error: _friendly(e));
    }
  }

  @override
  Future<({League? league, Failure? error})> join(String code) async {
    try {
      final found = await findByCode(code);
      if (found.error != null) {
        return (league: null, error: found.error);
      }
      if (found.league == null) {
        return (
          league: null,
          error: const NotFoundFailure(
            message: 'El código no es válido o la liga ya no existe.',
          ),
        );
      }
      await dataSource.join(found.league!.id);
      return (league: found.league, error: null);
    } on supabase.PostgrestException catch (e) {
      if (e.code == '23505') {
        return (
          league: null,
          error: const AuthFailure(message: 'Ya eres parte de esta liga.'),
        );
      }
      return (league: null, error: _friendly(e));
    } catch (e) {
      return (league: null, error: _friendly(e));
    }
  }

  @override
  Future<Failure?> leave(String leagueId) async {
    try {
      await dataSource.leave(leagueId);
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  /// Traduce errores de red/RLS del SDK a mensajes legibles. Los errores de la
  /// capacidad de la liga llegan como P0001 (raise del trigger).
  Failure _friendly(Object error) {
    if (error is supabase.PostgrestException) {
      final msg = error.message.toLowerCase();
      if (error.code == 'P0001' && msg.contains('llena')) {
        return const AuthFailure(
          message: 'La liga está completa (máximo 10 miembros).',
        );
      }
      return ServerFailure(message: _friendlyServerMessage(error.message));
    }
    if (error is supabase.AuthException) {
      return AuthFailure(message: _friendlyServerMessage(error.message));
    }
    return ServerFailure(message: _friendlyServerMessage(error.toString()));
  }

  String _friendlyServerMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('failed to decode') ||
        lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('handshake') ||
        lower.contains('network')) {
      return 'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.';
    }
    if (lower.contains('row-level security') ||
        lower.contains('rls') ||
        lower.contains('policy')) {
      return 'No tienes permiso para hacer eso en esta liga.';
    }
    if (lower.contains('unauthorized') ||
        lower.contains('jwt expired') ||
        lower.contains('invalid jwt') ||
        lower.contains('could not read jwt')) {
      return 'Tu sesión expiró. Inicia sesión de nuevo.';
    }
    return raw;
  }
}

League _leagueFromMap(Map<String, dynamic> row, {int? memberCount}) {
  return League(
    id: row['id'] as String,
    name: row['name'] as String,
    emoji: (row['emoji'] as String?) ?? '🏆',
    code: row['code'] as String,
    ownerId: row['owner_id'] as String,
    maxMembers: (row['max_members'] as num).toInt(),
    createdAt: DateTime.parse(row['created_at'] as String),
    memberCount: memberCount ?? 0,
  );
}

LeagueMember _memberFromMap(Map<String, dynamic> row) {
  final user = (row['users'] as Map?) ?? const <String, dynamic>{};
  return LeagueMember(
    userId: row['user_id'] as String,
    displayName: (user['display_name'] as String?) ?? 'Rival',
    alias: user['alias'] as String?,
    photoUrl: user['photo_url'] as String?,
    weeklyPoints: (row['weekly_points'] as num?)?.toInt() ?? 0,
    joinedAt: DateTime.parse(row['joined_at'] as String),
  );
}

UserSearchResult _searchFromMap(Map<String, dynamic> row) {
  return UserSearchResult(
    id: row['id'] as String,
    displayName: (row['display_name'] as String?) ?? 'Rival',
    alias: row['alias'] as String?,
    photoUrl: row['photo_url'] as String?,
  );
}