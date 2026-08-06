import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/school_info_remote_datasource.dart';
import '../../data/repositories/school_info_repository_impl.dart';
import '../../domain/entities/school_info_entity.dart';
import '../../domain/repositories/school_info_repository.dart';

final schoolInfoRemoteDataSourceProvider = Provider<SchoolInfoRemoteDataSource>((ref) {
  return SchoolInfoRemoteDataSource(ref.watch(dioClientProvider));
});

final schoolInfoRepositoryProvider = Provider<SchoolInfoRepository>((ref) {
  return SchoolInfoRepositoryImpl(ref.watch(schoolInfoRemoteDataSourceProvider));
});

final schoolInfoProvider = FutureProvider.autoDispose<SchoolInfoEntity>((ref) {
  return ref.watch(schoolInfoRepositoryProvider).getMySchoolInfo();
});
