import 'dart:async';
import 'dart:typed_data';

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
  final String? rankingError;
  final bool rankingLoading;
  final String? photoError;

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
    this.rankingError,
    this.rankingLoading = false,
    this.photoError,
    this.pendingJoinCode,
    this.joinInProgress = false,
  });

  LeagueState copyWith({
    LeagueStatus? status,
    Object? league = _unset,
    List<LeagueMember>? ranking,
    Object? errorMessage = _unset,
    Object? rankingError = _unset,
    bool? rankingLoading,
    Object? photoError = _unset,
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
      rankingError: identical(rankingError, _unset)
          ? this.rankingError
          : rankingError as String?,
      rankingLoading: rankingLoading ?? this.rankingLoading,
      photoError: identical(photoError, _unset)
          ? this.photoError
          : photoError as String?,
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
  ({String leagueId, Uint8List bytes, String fileName})? _pendingPhoto;
  Object? _rankingRequest;
  bool _rankingRefreshQueued = false;

  LeagueController(this._repo) : super(const LeagueState());

  /// Recarga liga + clasificacion desde el servidor.
  Future<void> load() async {
    if (state.status == LeagueStatus.loading) return;
    await _refresh();
  }

  Future<void> _refresh() async {
    state = state.copyWith(status: LeagueStatus.loading, errorMessage: null);

    final me = await _repo.getMyLeague();
    if (!mounted) return;
    if (me.error != null) {
      state = state.copyWith(
        status: LeagueStatus.error,
        errorMessage: me.error!.message,
      );
      return;
    }
    final league = me.league;
    final sameLeague = league?.id == state.league?.id;
    if (!sameLeague) _pendingPhoto = null;
    state = state.copyWith(
      status: LeagueStatus.loaded,
      league: league,
      ranking: sameLeague ? state.ranking : const [],
      rankingError: null,
      rankingLoading: sameLeague && state.rankingLoading,
      photoError: sameLeague ? state.photoError : null,
    );
    if (league != null) await loadRanking();
  }

  Future<void> loadRanking() async {
    final leagueId = state.league?.id;
    if (leagueId == null) return;
    if (state.rankingLoading) {
      _rankingRefreshQueued = true;
      return;
    }
    final request = _rankingRequest = Object();
    state = state.copyWith(rankingLoading: true, rankingError: null);
    do {
      _rankingRefreshQueued = false;
      final ranking = await _repo.getRanking(leagueId);
      if (!mounted ||
          state.league?.id != leagueId ||
          !identical(_rankingRequest, request)) {
        return;
      }
      if (_rankingRefreshQueued) continue;
      state = state.copyWith(
        rankingLoading: false,
        rankingError: ranking.error?.message,
        ranking: ranking.error == null ? ranking.items : state.ranking,
      );
      return;
    } while (true);
  }

  Future<void> retryPhoto() async {
    final photo = _pendingPhoto;
    if (photo == null || state.league?.id != photo.leagueId) return;
    _pendingPhoto = null;
    state = state.copyWith(photoError: null);
    final error = await _repo.uploadLeaguePhoto(
      leagueId: photo.leagueId,
      bytes: photo.bytes,
      fileName: photo.fileName,
    );
    if (!mounted || state.league?.id != photo.leagueId) return;
    if (error != null) {
      _pendingPhoto = photo;
      state = state.copyWith(
        photoError: 'No pudimos guardar la foto de la liga.',
      );
      return;
    }
    final refreshed = await _repo.getMyLeague();
    if (!mounted || state.league?.id != photo.leagueId) return;
    if (refreshed.league?.id == photo.leagueId) {
      state = state.copyWith(league: refreshed.league);
    }
  }

  void retry() => load();

  /// Publica la liga confirmada antes de cargar la foto y la clasificación.
  Future<String?> createLeague(
    String name, {
    String emoji = '🏆',
    String? socialBet,
    Uint8List? photoBytes,
    String? photoFileName,
  }) async {
    if (name.trim().isEmpty) {
      return 'Escribe un nombre para tu liga';
    }
    if (state.status == LeagueStatus.loading) {
      return 'Hay una operación en curso.';
    }
    if (state.league != null) return 'Ya perteneces a una liga.';
    state = state.copyWith(status: LeagueStatus.loading, errorMessage: null);
    final result = await _repo.createLeague(
      name.trim(),
      emoji: emoji,
      socialBet: socialBet,
    );
    if (!mounted) return 'No pudimos confirmar la creación.';
    final league = result.league;
    if (result.error != null || league == null) {
      state = state.copyWith(status: LeagueStatus.loaded);
      return result.error?.message ?? 'No pudimos confirmar la creación.';
    }
    state = state.copyWith(
      status: LeagueStatus.loaded,
      league: league,
      ranking: const [],
      rankingError: null,
      rankingLoading: false,
      photoError: null,
    );
    if (photoBytes != null && photoFileName != null) {
      _pendingPhoto = (
        leagueId: league.id,
        bytes: photoBytes,
        fileName: photoFileName,
      );
      unawaited(retryPhoto());
    }
    unawaited(loadRanking());
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
