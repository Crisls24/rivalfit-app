import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rivalfit/core/error/failures.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';
import 'package:rivalfit/features/league/domain/repositories/league_repository.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_controller.dart';

class _Repository extends Mock implements LeagueRepository {}

void main() {
  test(
    'creation publishes the league and retries optional work separately',
    () async {
      final repository = _Repository();
      final controller = LeagueController(repository);
      addTearDown(controller.dispose);
      late LeagueState state;
      controller.addListener((value) => state = value);
      final league = League(
        id: 'league-1',
        name: 'Los del lunes',
        code: 'ABC123',
        ownerId: 'owner',
        maxMembers: 10,
        memberCount: 1,
        createdAt: DateTime.utc(2026),
      );
      final photo = Uint8List.fromList([1]);
      final upload = Completer<Failure?>();
      final ranking = Completer<({List<LeagueMember> items, Failure? error})>();
      when(
        () => repository.createLeague(
          league.name,
          emoji: any(named: 'emoji'),
          socialBet: any(named: 'socialBet'),
        ),
      ).thenAnswer((_) async => (league: league, error: null));
      when(() => repository.getRanking(league.id))
          .thenAnswer((_) => ranking.future);
      when(
        () => repository.uploadLeaguePhoto(
          leagueId: league.id,
          bytes: photo,
          fileName: 'liga.png',
        ),
      ).thenAnswer((_) => upload.future);

      final error = await controller.createLeague(
        league.name,
        photoBytes: photo,
        photoFileName: 'liga.png',
      );
      expect(error, isNull);
      expect(state.league?.code, league.code);
      expect(state.status, LeagueStatus.loaded);
      expect(state.rankingLoading, isTrue);
      expect(upload.isCompleted, isFalse);

      upload.complete(const NetworkFailure());
      ranking.complete((
        items: <LeagueMember>[],
        error: const NetworkFailure(),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(state.league, same(league));
      expect(state.photoError, isNotNull);
      expect(state.rankingError, isNotNull);

      when(() => repository.getRanking(league.id))
          .thenAnswer((_) async => (items: <LeagueMember>[], error: null));
      await controller.loadRanking();
      expect(state.rankingError, isNull);
      expect(state.photoError, isNotNull);

      when(
        () => repository.uploadLeaguePhoto(
          leagueId: league.id,
          bytes: photo,
          fileName: 'liga.png',
        ),
      ).thenAnswer((_) async => null);
      when(repository.getMyLeague)
          .thenAnswer((_) async => (league: league, error: null));
      await controller.retryPhoto();
      expect(state.photoError, isNull);
      verify(
        () => repository.createLeague(
          league.name,
          emoji: any(named: 'emoji'),
          socialBet: any(named: 'socialBet'),
        ),
      ).called(1);
    },
  );
}
