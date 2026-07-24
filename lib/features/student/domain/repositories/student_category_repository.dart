import '../models/student_category_detail.dart';

/// Seam over the Student Categories management API — separate from
/// [StudentRepository]'s lightweight `fetchCategories()` (Enroll form
/// dropdown only). Reference: apps/students — StudentCategoryViewSet.
abstract class StudentCategoryRepository {
  Future<List<StudentCategoryDetail>> fetchCategories({String? search, String? status});

  Future<StudentCategorySummary> fetchSummary();

  /// Returns true if [name] is already taken by another category (excluding
  /// [excludeId], used while editing).
  Future<bool> isNameTaken(String name, {int? excludeId});

  Future<StudentCategoryDetail> createCategory({
    required String name,
    required String description,
    required String code,
    required String status,
  });

  Future<StudentCategoryDetail> updateCategory(
    int id, {
    required String name,
    required String description,
    required String code,
    required String status,
  });

  /// Throws with a message indicating the category is in use if the
  /// backend rejects the delete (server returns HTTP 400 when students are
  /// still assigned — see student_category_repository_impl.dart doc
  /// comment for the full gap disclosure).
  Future<void> deleteCategory(int id);

  Future<void> bulkSetStatus(List<int> ids, {required String status});

  Future<void> bulkDelete(List<int> ids);
}
