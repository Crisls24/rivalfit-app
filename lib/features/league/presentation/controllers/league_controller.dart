import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';
import 'package:rivalfit/features/league/domain/repositories/league_repository.dart';

enum LeagueStatus { idle, loading, loaded, error }

class LeagueState {
  final LeagueStatus status;

  /// Liga del usuario (null = sin liga).
  final League? league;

  /// Clasificacion de la liga (weekly_points desc).
  final List<LeagueMember> ranking;

  final String? errorMessage;

  /// Codigo de invitacion recibido por deep link mientras no habia sesion.
  /// Se consume al abrir la pagina /join/:code.
  final String? pendingJoinCode;

  /// True mientras una invitacion se esta procesando.
  final bool joinInProgress;

  const LeagueState({
    this.status = LeagueStatus.idle,
    this.league,
    this.ranking = const [],
    this.errorMessage,
    this.pendingJoinCode,
    this.joinInProgress = false,
  });

  LeagueState copyWith({
    LeagueStatus? status,
    Object? league = _unset,
    List<LeagueMember>? ranking,
    Object? errorMessage = _unset,
    Object? pendingJoinCode = _unset,
    bool? joinInProgress,
  }) {
    return LeagueState(
      status: status ?? this.status,
      league: identical(league, _unset) ? this.league : league as League?,
      ranking: ranking ?? this.ranking,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      pendingJoinCode: identical(pendingJoinCode, _unset)
          ? this.pendingJoinCode
          : pendingJoinCode as String?,
      joinInProgress: joinInProgress ?? this.joinInProgress,
    );
  }

  static const _unset = Object();
}

class LeagueController extends StateNotifier<LeagueState> {
  final LeagueRepository _repo;

  LeagueController(this._repo) : super(const LeagueState());

  /// Recarga liga + clasificacion desde el servidor.
  Future<void> load() async {
    if (state.status == LeagueStatus.loading) return;
    await _refresh();
  }

  Future<void> _refresh() async {
    state = state.copyWith(status: LeagueStatus.loading, errorMessage: null);

    final me = await _repo.getMyLeague();
    if (me.error != null) {
      state = state.copyWith(
        status: LeagueStatus.error,
        errorMessage: me.error!.message,
      );
      return;
    }
    if (me.league == null) {
      state = state.copyWith(
        status: LeagueStatus.loaded,
        league: null,
        ranking: const [],
      );
      return;
    }

    final ranking = await _repo.getRanking(me.league!.id);
    if (ranking.error != null) {
      state = state.copyWith(
        status: LeagueStatus.error,
        errorMessage: ranking.error!.message,
      );
      return;
    }
    state = state.copyWith(
      status: LeagueStatus.loaded,
      league: me.league,
      ranking: ranking.items,
    );
  }

  void retry() => load();

  /// Crea la liga y recarga el estado. Devuelve un mensaje de error o null.
  Future<String?> createLeague(String name, {String emoji = '🏆'}) async {
    if (name.trim().isEmpty) {
      return 'Escribe un nombre para tu liga';
    }
    if (state.status == LeagueStatus.loading) return null;
    state = state.copyWith(status: LeagueStatus.loading, errorMessage: null);
    final result = await _repo.createLeague(name.trim(), emoji: emoji);
    if (result.error != null) {
      state = state.copyWith(
        status: LeagueStatus.error,
        errorMessage: result.error!.message,
      );
      return result.error!.message;
    }
    await _refresh();
    return null;
  }

  /// Une al usuario por codigo de invitacion y recarga el estado.
  /// Devuelve un mensaje de error o null.
  Future<String?> join(String code) async {
    if (state.joinInProgress) return null;
    state = state.copyWith(joinInProgress: true, errorMessage: null);
    final result = await _repo.join(code);
    if (result.error != null) {
      state = state.copyWith(
        joinInProgress: false,
        errorMessage: result.error!.message,
      );
      return result.error!.message;
    }
    state = state.copyWith(joinInProgress: false, errorMessage: null);
    await _refresh();
    return null;
  }

  /// Sale de la liga actual y recarga. Devuelve un mensaje de error o null.
  Future<String?> leave() async {
    final league = state.league;
    if (league == null) return 'No estás en ninguna liga';
    state = state.copyWith(status: LeagueStatus.loading, errorMessage: null);
    final error = await _repo.leave(league.id);
    if (error != null) {
      state = state.copyWith(
        status: LeagueStatus.error,
        errorMessage: error.message,
      );
      return error.message;
    }
    await _refresh();
    return null;
  }

  /// Guarda el codigo de una invitacion recibida sin sesion activa.
  void setPendingJoinCode(String? code) {
    if (code == null || code.isEmpty) return;
    state = state.copyWith(pendingJoinCode: code);
  }

  /// Extrae y descarta el codigo pendiente (lo llama la pagina /join/:code).
  String? consumePendingJoinCode() {
    final code = state.pendingJoinCode;
    if (code != null) {
      state = state.copyWith(pendingJoinCode: null);
    }
    return code;
  }
}