import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/fees_collection_remote_datasource.dart';
import '../../data/repositories/fees_collection_repository_impl.dart';
import '../../domain/repositories/fees_collection_repository.dart';

final feesCollectionRemoteDataSourceProvider = Provider<FeesCollectionRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return FeesCollectionRemoteDataSourceImpl(dio);
});

final feesCollectionRepositoryProvider = Provider<FeesCollectionRepository>((ref) {
  final remoteDataSource = ref.watch(feesCollectionRemoteDataSourceProvider);
  return FeesCollectionRepositoryImpl(remoteDataSource);
});
