/// One generated AI review — Source: backend
/// apps/competitions/serializers.py::AIReviewResponseItemSerializer.
class AiReviewResultItem {
  final int? studentId;
  final String review;
  final bool cacheHit;
  final bool fallback;
  const AiReviewResultItem({this.studentId, required this.review, required this.cacheHit, required this.fallback});

  factory AiReviewResultItem.fromJson(Map<String, dynamic> json) {
    return AiReviewResultItem(
      studentId: json['student_id'] as int?,
      review: (json['review'] as String?) ?? '',
      cacheHit: json['cache_hit'] == true,
      fallback: json['fallback'] == true,
    );
  }
}

/// Best-effort sync of InspireHub data to the real Django backend
/// (apps/competitions). Competitions and results are owned primarily by the
/// on-device InspireHubStore; this seam is used to create a backend
/// Competition row (so results have somewhere to attach), bulk-persist
/// results once a teacher explicitly saves, and generate AI-written
/// reviews. All three calls degrade gracefully — the caller falls back to a
/// local-only draft / templated review on failure, never blocking the UI.
abstract class CompetitionsRepository {
  Future<Map<String, dynamic>> createCompetition(Map<String, dynamic> payload);
  Future<void> bulkCreateResults(List<Map<String, dynamic>> payload);
  Future<List<AiReviewResultItem>> generateReviews(List<Map<String, dynamic>> items);
}
