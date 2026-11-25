import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/home/presentation/widgets/muscle_map_card.dart';
import 'package:rivalfit/features/league/domain/models/league.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_standings.dart';

LeagueMember member(
  String id,
  int points, {
  int? legs,
  int? chest,
  String? alias,
  DailyAward? award,
}) => LeagueMember(
  userId: id,
  displayName: id,
  alias: alias,
  weeklyPoints: points,
  joinedAt: DateTime.utc(2026),
  legReps: legs,
  chestArmReps: chest,
  dailyAward: award,
);

Future<void> showBoard(WidgetTester tester, List<LeagueMember> members) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: LeagueStandings(members: members, currentUserId: 'me'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    '320dp Android podium aligns identities, fits artwork and opens individual maps',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final players = [
        member(
          'leader',
          21,
          legs: 0,
          chest: 21,
          alias: 'UnAliasLarguísimoParaElPodio',
        ),
        member('second', 16, legs: 16, chest: 0),
        member('third', 11),
        member('me', 4),
      ];
      await showBoard(tester, players);
      Finder tile(String id) => find.byKey(ValueKey('member-$id'));
      final center = tester.getCenter(tile('leader')).dx;
      expect(tester.getCenter(tile('second')).dx, lessThan(center));
      expect(tester.getCenter(tile('third')).dx, greaterThan(center));
      final left = tester.getRect(find.text('16 pts')),
          mid = tester.getRect(find.text('21 pts'));
      expect(left.top, closeTo(mid.top, .1));
      final firstMap = find.descendant(
        of: tile('leader'),
        matching: find.byType(MuscleBodyMap),
      );
      final secondMap = find.descendant(
        of: tile('second'),
        matching: find.byType(MuscleBodyMap),
      );
      expect(
        tester.getSize(firstMap).height / tester.getSize(secondMap).height,
        closeTo(1.15, .01),
      );
      expect(tester.widget<MuscleBodyMap>(firstMap).chestArmReps, 21);
      expect(tester.widget<MuscleBodyMap>(secondMap).legReps, 16);
      expect(find.text('Pecho y brazos'), findsOneWidget);
      await tester.tap(tile('leader'));
      await tester.pumpAndSettle();
      expect(find.text('21 reps confirmadas'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(tile('me'));
      await tester.tap(tile('me'));
      await tester.pumpAndSettle();
      expect(find.text('Mapa muscular sin datos compartidos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'small leagues show real members and equal scores share a place',
    (tester) async {
      final a = member('Ana', 0), b = member('Beto', 0);
      await showBoard(tester, [a]);
      expect(find.byType(MuscleBodyMap), findsOneWidget);
      expect(find.text('¿Quién suma primero?'), findsOneWidget);
      await showBoard(tester, [a, b]);
      expect(find.byType(MuscleBodyMap), findsNWidgets(2));
      expect(find.text('1.º'), findsNWidgets(2));
      expect(find.textContaining('LIDERATO'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'only a dated shared award is presented, ahead of the remaining rows',
    (tester) async {
      for (final closed in [false, true]) {
        await showBoard(tester, [
          member(
            'Ana',
            12,
            award: (reps: 12, day: DateTime(2026, 11, 24), closed: closed),
          ),
          member('Beto', 9),
          member('Cris', 8),
          member('me', 4),
        ]);
        final award = find.textContaining(
          closed ? 'GANADOR DEL DÍA' : 'LIDERATO EN CURSO',
        );
        expect(
          tester.getTopLeft(award).dy,
          lessThan(tester.getTopLeft(find.text('Clasificación')).dy),
        );
        expect(find.text('12 reps confirmadas'), findsOneWidget);
      }
    },
  );
}
