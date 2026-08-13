import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/broadcast_remote_datasource.dart';
import '../../data/repositories/broadcast_repository_impl.dart';
import '../../domain/entities/broadcast_entity.dart';
import '../../domain/repositories/broadcast_repository.dart';

final broadcastRemoteDataSourceProvider = Provider<BroadcastRemoteDataSource>((ref) {
  return BroadcastRemoteDataSource(ref.watch(dioClientProvider));
});

final broadcastRepositoryProvider = Provider<BroadcastRepository>((ref) {
  return BroadcastRepositoryImpl(ref.watch(broadcastRemoteDataSourceProvider));
});

final audienceOptionsProvider = FutureProvider.autoDispose<BroadcastAudienceOptionsEntity>((ref) {
  return ref.watch(broadcastRepositoryProvider).getAudienceOptions();
});
