import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/ai_assistant_remote_datasource.dart';
import '../../data/ai_planner_store.dart';
import '../../data/ai_todo_store.dart';

final aiAssistantRemoteDataSourceProvider = Provider<AiAssistantRemoteDataSource>((ref) {
  return AiAssistantRemoteDataSource(ref.watch(dioProvider));
});

final aiTodoStoreProvider = Provider<AiTodoStore>((ref) => AiTodoStore());

final aiPlannerStoreProvider = Provider<AiPlannerStore>((ref) => AiPlannerStore());
