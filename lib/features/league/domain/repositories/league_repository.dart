import 'dart:typed_data';

import 'package:rivalfit/core/error/failures.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';

abstract class LeagueRepository {
  /// Liga del usuario autenticado (null si no pertenece a ninguna).
  Future<({League? league, Failure? error})> getMyLeague();

  /// Busca una liga por su codigo de invitacion.
  Future<({League? league, Failure? error})> findByCode(String code);

  /// Clasificacion de la liga ordenada por weekly_points desc.
  Future<({List<LeagueMember> items, Failure? error})> getRanking(
    String leagueId,
  );

  /// Busca usuarios por alias o nombre para invitar.
  Future<({List<UserSearchResult> items, Failure? error})> searchByAlias(
    String query,
  );

  /// Crea una liga (el creador queda como miembro automaticamente).
  Future<({League? league, Failure? error})> createLeague(
    String name, {
    String emoji = '🏆',
    String? socialBet,
  });

  /// Sube la foto de grupo de una liga recien creada al bucket (avatars) y
  /// guarda la URL publica en la fila. Devuelve null si salio bien.
  Future<Failure?> uploadLeaguePhoto({
    required String leagueId,
    required Uint8List bytes,
    required String fileName,
  });

  /// Une al usuario autenticado por codigo de invitacion.
  Future<({League? league, Failure? error})> join(String code);

  /// Saca al usuario autenticado de su liga.
  Future<Failure?> leave(String leagueId);
}
