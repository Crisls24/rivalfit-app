import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/league/presentation/widgets/league_dialogs.dart';

void main() {
  test('leagueIconData keeps a stable icon map for the v1 identity', () {
    expect(leagueIconKeys, contains('podium'));
    expect(leagueIconData('podium'), Icons.emoji_events_rounded);
    expect(leagueIconData('bolt'), Icons.bolt_rounded);
  });
}
