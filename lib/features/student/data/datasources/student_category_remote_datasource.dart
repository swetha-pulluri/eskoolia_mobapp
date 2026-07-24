import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/student_category_detail.dart';

abstract class StudentCategoryRemoteDataSource {
  Future<List<StudentCategoryDetail>> fetchCategories({String? search, String? status});
  Future<StudentCategorySummary> fetchSummary();
  Future<bool> isNameTaken(String name, {int? excludeId});
  Future<StudentCategoryDetail> createCategory(Map<String, dynamic> body);
  Future<StudentCategoryDetail> updateCategory(int id, Map<String, dynamic> body);
  Future<void> deleteCategory(int id);
  Future<void> bulkSetStatus(List<int> ids, String status);
  Future<void> bulkDelete(List<int> ids);
}

class StudentCategoryRemoteDataSourceImpl implements StudentCategoryRemoteDataSource {
  final Dio _dio;
  StudentCategoryRemoteDataSourceImpl(this._dio);

  @override
  Future<List<StudentCategoryDetail>> fetchCategories({String? search, String? status}) async {
    try {
      final response = await _dio.get(
        ApiConstants.studentCategories,
        queryParameters: {
          'page_size': 200,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>? ?? const [];
      return results.map((e) => StudentCategoryDetail.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load categories.');
    }
  }

  @override
  Future<StudentCategorySummary> fetchSummary() async {
    try {
      final response = await _dio.get(ApiConstants.categorySummary);
      final body = response.data as Map<String, dynamic>;
      return StudentCategorySummary.fromJson(body['data'] as Map<String, dynamic>? ?? body);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load category summary.');
    }
  }

  @override
  Future<bool> isNameTaken(String name, {int? excludeId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.categoryCheckName,
        queryParameters: {'name': name, 'exclude_id': ?excludeId},
      );
      final body = response.data as Map<String, dynamic>;
      return (body['taken'] as bool?) ?? (body['exists'] as bool?) ?? false;
    } on DioException {
      // Non-critical: if the check itself fails, don't block the form —
      // the create/update call will still surface a real uniqueness error.
      return false;
    }
  }

  @override
  Future<StudentCategoryDetail> createCategory(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.studentCategories, data: body);
      return StudentCategoryDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to create category.');
    }
  }

  @override
  Future<StudentCategoryDetail> updateCategory(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(ApiConstants.categoryDetail(id), data: body);
      return StudentCategoryDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update category.');
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete(ApiConstants.categoryDetail(id));
    } on DioException catch (e) {
      // The real backend blocks delete with HTTP 400 (not the 409 +
      // {code:"CATEGORY_IN_USE"} contract the frontend's conflict-modal
      // expects) when students are still assigned — surface the server's
      // own message rather than trying to reproduce that richer contract.
      throw Exception(e.error ?? 'Failed to delete category — it may still have students assigned.');
    }
  }

  @override
  Future<void> bulkSetStatus(List<int> ids, String status) async {
    try {
      await _dio.patch(ApiConstants.categoryBulkStatus, data: {'ids': ids, 'status': status});
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update categories.');
    }
  }

  @override
  Future<void> bulkDelete(List<int> ids) async {
    try {
      await _dio.delete(ApiConstants.categoryBulkDelete, data: {'ids': ids});
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to delete categories.');
    }
  }
}
