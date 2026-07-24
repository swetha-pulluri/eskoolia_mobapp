import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/fees_assignment_remote_datasource.dart';
import '../../data/repositories/fees_assignment_repository_impl.dart';
import '../../domain/repositories/fees_assignment_repository.dart';

final feesAssignmentRemoteDataSourceProvider = Provider<FeesAssignmentRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return FeesAssignmentRemoteDataSourceImpl(dio);
});

final feesAssignmentRepositoryProvider = Provider<FeesAssignmentRepository>((ref) {
  final remoteDataSource = ref.watch(feesAssignmentRemoteDataSourceProvider);
  return FeesAssignmentRepositoryImpl(remoteDataSource);
});
