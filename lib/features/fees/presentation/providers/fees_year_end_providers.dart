import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/fees_year_end_remote_datasource.dart';
import '../../data/repositories/fees_year_end_repository_impl.dart';
import '../../domain/repositories/fees_year_end_repository.dart';

final feesYearEndRemoteDataSourceProvider = Provider<FeesYearEndRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return FeesYearEndRemoteDataSourceImpl(dio);
});

final feesYearEndRepositoryProvider = Provider<FeesYearEndRepository>((ref) {
  final remoteDataSource = ref.watch(feesYearEndRemoteDataSourceProvider);
  return FeesYearEndRepositoryImpl(remoteDataSource);
});
