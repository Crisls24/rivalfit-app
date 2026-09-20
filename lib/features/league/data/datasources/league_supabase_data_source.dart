import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso a las tablas de ligas de Supabase (PRD RF-7). Todo funciona bajo la
/// RLS del backend: los miembros solo ven su propia liga y los usuarios pueden
/// buscar perfiles por alias para invitar.
class LeagueSupabaseDataSource {
  /// Si el servidor no responde en ese plazo, la llamada aborta con un error
  /// amigable en lugar de dejar el spinner girando para siempre.
  static const _requestTimeout = Duration(seconds: 20);

  final SupabaseClient _client;

  LeagueSupabaseDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Devuelve la liga del usuario autenticado, o null si no pertenece a ninguna.
  Future<Map<String, dynamic>?> getMyLeague() async {
    final uid = _userId;
    if (uid == null) {
      throw const AuthException('No autenticado');
    }
    final row = await _client
        .from('league_members')
        .select('league_id, leagues(*)')
        .eq('user_id', uid)
        .maybeSingle()
        .timeout(_requestTimeout);
    if (row == null) return null;
    return row['leagues'] as Map<String, dynamic>;
  }

  /// Busca una liga por su codigo de invitacion (6 caracteres, case-insensitive).
  /// Devuelve null si el codigo no existe.
  Future<Map<String, dynamic>?> findByCode(String code) async {
    final row = await _client
        .from('leagues')
        .select('*')
        .eq('code', code.trim().toUpperCase())
        .maybeSingle()
        .timeout(_requestTimeout);
    return row;
  }

  /// Numero de miembros de una liga (funcion security definer para que el
  /// enlace de invitacion pueda mostrarlo sin romper la RLS de league_members).
  Future<int> memberCount(String leagueId) async {
    final result = await _client
        .rpc('league_member_count', params: {'lid': leagueId})
        .timeout(_requestTimeout);
    return (result as num).toInt();
  }

  /// Ranking de la liga ordenado por puntos semanales desc (empatados: antes
  /// quien se unio primero).
  Future<List<Map<String, dynamic>>> getRanking(String leagueId) async {
    final rows = await _client
        .from('league_members')
        .select(
          'league_id, user_id, weekly_points, joined_at, '
          'users(display_name, alias, photo_url)',
        )
        .eq('league_id', leagueId)
        .order('weekly_points', ascending: false)
        .order('joined_at', ascending: true)
        .timeout(_requestTimeout);
    return rows;
  }

  /// Crea una liga. El codigo de invitacion y el owner los resuelve el backend
  /// (triggers set_league_code / add_owner_as_member).
  Future<Map<String, dynamic>> createLeague(String name, {String emoji = '🏆'}) async {
    final row = await _client
        .from('leagues')
        .insert({'name': name, 'emoji': emoji})
        .select()
        .single()
        .timeout(_requestTimeout);
    return row;
  }

  /// Une al usuario autenticado a la liga por su codigo. El user_id lo resuelve
  /// el trigger `trg_members_set_user`; la capacidad la valida
  /// `trg_league_capacity` (igual si ya es miembro: unique league_id+user_id).
  Future<void> join(String leagueId) async {
    await _client
        .from('league_members')
        .insert({'league_id': leagueId})
        .timeout(_requestTimeout);
  }

  /// Saca al usuario autenticado de la liga (tambien envia la confirmacion para
  /// que PostgREST aplique la policy de delete de la fila propia).
  Future<void> leave(String leagueId) async {
    final uid = _userId;
    if (uid == null) {
      throw const AuthException('No autenticado');
    }
    await _client
        .from('league_members')
        .delete()
        .eq('league_id', leagueId)
        .eq('user_id', uid)
        .timeout(_requestTimeout);
  }

  /// Busca usuarios por @alias o nombre (wildcard `*` de PostgREST = LIKE).
  Future<List<Map<String, dynamic>>> searchByAlias(String query) async {
    final uid = _userId;
    if (uid == null) {
      throw const AuthException('No autenticado');
    }
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final rows = await _client
        .from('users')
        .select('id, display_name, alias, photo_url')
        .or('alias.ilike.*$q*,display_name.ilike.*$q*')
        .neq('id', uid)
        .limit(20)
        .timeout(_requestTimeout);
    return rows;
  }
}