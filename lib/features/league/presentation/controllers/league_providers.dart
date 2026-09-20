import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rivalfit/features/league/data/datasources/league_supabase_data_source.dart';
import 'package:rivalfit/features/league/data/repositories/league_repository_impl.dart';
import 'package:rivalfit/features/league/domain/repositories/league_repository.dart';
import 'package:rivalfit/features/league/presentation/controllers/league_controller.dart';

final supabaseLeagueDataSourceProvider =
    Provider<LeagueSupabaseDataSource>((ref) {
  return LeagueSupabaseDataSource();
});

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  return LeagueRepositoryImpl(
    dataSource: ref.watch(supabaseLeagueDataSourceProvider),
  );
});

final leagueControllerProvider =
    StateNotifierProvider<LeagueController, LeagueState>((ref) {
  return LeagueController(ref.watch(leagueRepositoryProvider));
});