import '../../domain/models/login_permission_api_results.dart';
import '../../domain/models/login_permission_meta.dart';
import '../../domain/repositories/login_permission_repository.dart';
import '../datasources/login_permission_remote_datasource.dart';

/// Login Permission Repository Implementation
/// Implements the domain repository interface
class LoginPermissionRepositoryImpl implements LoginPermissionRepository {
  final LoginPermissionRemoteDataSource _remoteDataSource;

  LoginPermissionRepositoryImpl(this._remoteDataSource);

  @override
  Future<MetaResult> fetchMeta() => _remoteDataSource.fetchMeta();

  @override
  Future<PageResult> listUsers({
    required String role,
    int page = 1,
    int pageSize = 100,
    String? search,
    String? status,
    String? classId,
    String? sectionId,
  }) {
    return _remoteDataSource.listUsers(
      role: role,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      classId: classId,
      sectionId: sectionId,
    );
  }

  @override
  Future<bool> toggleAccess(String id, bool loginAccess) =>
      _remoteDataSource.toggleAccess(id, loginAccess);

  @override
  Future<CredentialActionResult> resetPassword(String id) =>
      _remoteDataSource.resetPassword(id);

  @override
  Future<CredentialActionResult> setInitialPassword(
    String id, {
    required String mode,
    String? password,
  }) {
    return _remoteDataSource.setInitialPassword(
      id,
      mode: mode,
      password: password,
    );
  }

  @override
  Future<int> bulkSetAccess({
    required List<String> ids,
    required bool loginAccess,
  }) {
    return _remoteDataSource.bulkSetAccess(ids: ids, loginAccess: loginAccess);
  }

  @override
  Future<int> bulkResetPasswords({required List<String> ids}) {
    return _remoteDataSource.bulkResetPasswords(ids: ids);
  }
}
