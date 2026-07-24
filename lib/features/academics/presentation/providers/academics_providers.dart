import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/academics_remote_datasource.dart';
import '../../data/repositories/academics_repository_impl.dart';
import '../../domain/repositories/academics_repository.dart';

final academicsRepositoryProvider = Provider<AcademicsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AcademicsRepositoryImpl(AcademicsRemoteDataSourceImpl(dio));
});
