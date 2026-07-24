import '../../domain/models/student_category_detail.dart';
import '../../domain/repositories/student_category_repository.dart';
import '../datasources/student_category_remote_datasource.dart';

class StudentCategoryRepositoryImpl implements StudentCategoryRepository {
  final StudentCategoryRemoteDataSource _remote;
  StudentCategoryRepositoryImpl(this._remote);

  Map<String, dynamic> _body({
    required String name,
    required String description,
    required String code,
    required String status,
  }) {
    return {
      'name': name,
      'description': description,
      'code': code,
      'status': status,
    };
  }

  @override
  Future<List<StudentCategoryDetail>> fetchCategories({String? search, String? status}) =>
      _remote.fetchCategories(search: search, status: status);

  @override
  Future<StudentCategorySummary> fetchSummary() => _remote.fetchSummary();

  @override
  Future<bool> isNameTaken(String name, {int? excludeId}) => _remote.isNameTaken(name, excludeId: excludeId);

  @override
  Future<StudentCategoryDetail> createCategory({
    required String name,
    required String description,
    required String code,
    required String status,
  }) {
    return _remote.createCategory(_body(name: name, description: description, code: code, status: status));
  }

  @override
  Future<StudentCategoryDetail> updateCategory(
    int id, {
    required String name,
    required String description,
    required String code,
    required String status,
  }) {
    return _remote.updateCategory(id, _body(name: name, description: description, code: code, status: status));
  }

  @override
  Future<void> deleteCategory(int id) => _remote.deleteCategory(id);

  @override
  Future<void> bulkSetStatus(List<int> ids, {required String status}) => _remote.bulkSetStatus(ids, status);

  @override
  Future<void> bulkDelete(List<int> ids) => _remote.bulkDelete(ids);
}
