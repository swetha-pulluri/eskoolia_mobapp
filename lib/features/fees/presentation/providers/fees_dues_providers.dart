import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/fees_dues_remote_datasource.dart';
import '../../data/repositories/fees_dues_repository_impl.dart';
import '../../domain/repositories/fees_dues_repository.dart';

final feesDuesRemoteDataSourceProvider = Provider<FeesDuesRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return FeesDuesRemoteDataSourceImpl(dio);
});

final feesDuesRepositoryProvider = Provider<FeesDuesRepository>((ref) {
  final remoteDataSource = ref.watch(feesDuesRemoteDataSourceProvider);
  return FeesDuesRepositoryImpl(remoteDataSource);
});
