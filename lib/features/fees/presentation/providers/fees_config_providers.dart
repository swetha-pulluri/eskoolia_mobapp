import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/fees_config_remote_datasource.dart';
import '../../data/repositories/fees_config_repository_impl.dart';
import '../../domain/repositories/fees_config_repository.dart';

final feesConfigRemoteDataSourceProvider = Provider<FeesConfigRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return FeesConfigRemoteDataSourceImpl(dio);
});

final feesConfigRepositoryProvider = Provider<FeesConfigRepository>((ref) {
  final remoteDataSource = ref.watch(feesConfigRemoteDataSourceProvider);
  return FeesConfigRepositoryImpl(remoteDataSource);
});
