import 'package:flutter_test/flutter_test.dart';
import 'package:rivalfit/features/league/domain/invite_message.dart';

void main() {
  const link = 'https://fit-api.iscx.site/join/9KGHSB';

  test('leagueInviteMessage: formato profesional, retador y sin emojis', () {
    final msg = leagueInviteMessage(
      leagueName: 'LOS CABRONES',
      memberCount: 2,
      maxMembers: 10,
      link: link,
    );

    expect(msg, equals(
      'Te reto a mi Liga de RIVALFIT\n'
      'LOS CABRONES · 2/10 competidores\n'
      '\n'
      'Esta semana se reinicia el ranking.\n'
      '¿Vas a dejar que otro gane la Liga?\n'
      '\n'
      '$link',
    ));
  });

  test('leagueInviteMessage: el enlace queda solo en la ultima linea '
      '(para que WhatsApp extraiga el preview) y sin emojis', () {
    final msg = leagueInviteMessage(
      leagueName: 'Liga A',
      memberCount: 1,
      maxMembers: 10,
      link: link,
    );

    final lines = msg.trimRight().split('\n');
    expect(lines.last, link);
    expect(msg, isNot(contains('🟢')));
    expect(msg, isNot(contains('😀')));
  });
}