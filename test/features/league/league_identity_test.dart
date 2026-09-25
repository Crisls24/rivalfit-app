import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_emblem_icon.dart';

void main() {
  group('LeagueBadge identity v1', () {
    testWidgets('sin foto muestra el LeagueEmblem por defecto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: LeagueBadge())),
        ),
      );
      expect(find.byType(LeagueEmblem), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('con photoUrl muestra la foto de red', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LeagueBadge(photoUrl: 'https://x.test/p.png'),
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(LeagueEmblem), findsNothing);
    });

    testWidgets('con bytes locales muestra la foto en memoria', (tester) async {
      final png = Uint8List.fromList(kTransparentImage);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: LeagueBadge(bytes: png)),
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(LeagueEmblem), findsNothing);
    });
  });
}

const List<int> kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];