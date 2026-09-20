import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/features/league/data/datasources/league_supabase_data_source.dart';
import 'package:rivalfit/features/league/data/repositories/league_repository_impl.dart';
import 'package:rivalfit/features/league/domain/repositories/league_repository.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_controller.dart';

/// Data source de ligas sobre la instancia de Supabase activa.
final supabaseLeagueDataSourceProvider =
    Provider<LeagueSupabaseDataSource>((ref) {
  return LeagueSupabaseDataSource();
});

/// Repositorio de ligas construido sobre el data source de Supabase.
final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  return LeagueRepositoryImpl(
    dataSource: ref.watch(supabaseLeagueDataSourceProvider),
  );
});

/// Controlador compartido de la tab Liga (crear, unirse, ranking, salir).
final leagueControllerProvider =
    StateNotifierProvider<LeagueController, LeagueState>((ref) {
  return LeagueController(ref.watch(leagueRepositoryProvider));
});