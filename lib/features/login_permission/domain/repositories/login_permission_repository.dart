import '../models/login_permission_api_results.dart';
import '../models/login_permission_meta.dart';

/// Domain-facing seam over the Login Permission API.
/// Reference: backend/apps/access_control/views.py::LoginPermissionViewSet
abstract class LoginPermissionRepository {
  /// GET login-permission/meta/
  Future<MetaResult> fetchMeta();

  /// GET login-permission/users/
  Future<PageResult> listUsers({
    required String role,
    int page = 1,
    int pageSize = 100,
    String? search,
    String? status,
    String? classId,
    String? sectionId,
  });

  /// POST login-permission/toggle/ — returns the confirmed loginAccess value.
  Future<bool> toggleAccess(String id, bool loginAccess);

  /// POST login-permission/reset-password/
  Future<CredentialActionResult> resetPassword(String id);

  /// POST login-permission/set-initial-password/
  Future<CredentialActionResult> setInitialPassword(
    String id, {
    required String mode,
    String? password,
  });

  /// POST login-permission/bulk-access/ — returns the number of rows affected.
  Future<int> bulkSetAccess({
    required List<String> ids,
    required bool loginAccess,
  });

  /// POST login-permission/bulk-reset/ — returns the number of rows affected.
  Future<int> bulkResetPasswords({required List<String> ids});
}
