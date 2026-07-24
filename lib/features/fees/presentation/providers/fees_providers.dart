import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/fees_remote_datasource.dart';
import '../../data/repositories/fees_repository_impl.dart';
import '../../domain/repositories/fees_repository.dart';
import 'fees_home_notifier.dart';
import 'fees_home_state.dart';

/// Reuses the app-wide dioProvider (auth/error interceptors) — no separate
/// Dio instance, mirroring student_providers.dart / roles_providers.dart.
final feesRemoteDataSourceProvider = Provider<FeesRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return FeesRemoteDataSourceImpl(dio);
});

final feesRepositoryProvider = Provider<FeesRepository>((ref) {
  final remoteDataSource = ref.watch(feesRemoteDataSourceProvider);
  return FeesRepositoryImpl(remoteDataSource);
});

final feesHomeNotifierProvider =
    StateNotifierProvider.autoDispose<FeesHomeNotifier, FeesHomeState>((ref) {
      final repository = ref.watch(feesRepositoryProvider);
      return FeesHomeNotifier(repository);
    });
