import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autohost/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:autohost/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:autohost/features/auth/domain/repositories/auth_repository.dart';

final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>((ref) {
  return SupabaseAuthDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(supabaseAuthDataSourceProvider),
  );
});
