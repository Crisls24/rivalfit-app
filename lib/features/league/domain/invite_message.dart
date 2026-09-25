/// Mensaje profesional para compartir por WhatsApp/SMS/redes: corto, retador y
/// sin emojis. El enlace va solo en la ultima linea para que WhatsApp arme el
/// preview con los og: tags de la landing (/join/:code).
///
/// Es la UNICA fuente del texto de invitacion: lo usan tanto el success dialog
/// de "liga creada" como el invite sheet.
String leagueInviteMessage({
  required String leagueName,
  required int memberCount,
  required int maxMembers,
  required String link,
}) {
  return 'Te reto a mi Liga de RIVALFIT\n'
      '$leagueName · $memberCount/$maxMembers competidores\n'
      '\n'
      'Esta semana se reinicia el ranking.\n'
      '¿Vas a dejar que otro gane la Liga?\n'
      '\n'
      '$link';
}