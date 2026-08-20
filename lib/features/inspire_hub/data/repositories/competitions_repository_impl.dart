import '../../domain/repositories/competitions_repository.dart';
import '../datasources/competitions_remote_datasource.dart';

class CompetitionsRepositoryImpl implements CompetitionsRepository {
  final CompetitionsRemoteDataSource _remote;
  CompetitionsRepositoryImpl(this._remote);

  @override
  Future<Map<String, dynamic>> createCompetition(Map<String, dynamic> payload) =>
      _remote.createCompetition(payload);

  @override
  Future<void> bulkCreateResults(List<Map<String, dynamic>> payload) => _remote.bulkCreateResults(payload);

  @override
  Future<List<AiReviewResultItem>> generateReviews(List<Map<String, dynamic>> items) async {
    final raw = await _remote.generateReviews(items);
    return raw.map((e) => AiReviewResultItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
