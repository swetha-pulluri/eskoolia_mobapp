import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/competitions_remote_datasource.dart';
import '../../data/repositories/competitions_repository_impl.dart';
import '../../domain/inspire_hub_store.dart';
import '../../domain/repositories/competitions_repository.dart';

final competitionsRemoteDataSourceProvider = Provider<CompetitionsRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return CompetitionsRemoteDataSourceImpl(dio);
});

final competitionsRepositoryProvider = Provider<CompetitionsRepository>((ref) {
  return CompetitionsRepositoryImpl(ref.watch(competitionsRemoteDataSourceProvider));
});

/// Stateless CRUD store — a fresh instance is fine since all state actually
/// lives in shared_preferences, not in the object itself.
final inspireHubStoreProvider = Provider<InspireHubStore>((ref) => InspireHubStore());
