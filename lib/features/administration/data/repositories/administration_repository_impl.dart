import '../../domain/entities/visitor_entity.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/phone_call_entity.dart';
import '../../domain/entities/admin_setup_entity.dart';
import '../../domain/entities/postal_entity.dart';
import '../../domain/entities/student_category_entity.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/repositories/administration_repository.dart';
import '../datasources/administration_remote_datasource.dart';

class AdministrationRepositoryImpl implements AdministrationRepository {
  final AdministrationRemoteDataSource _remote;

  AdministrationRepositoryImpl(this._remote);

  @override
  Future<PaginatedResult<VisitorEntity>> getVisitors({int page = 1, int pageSize = 10, String? search}) {
    return _remote.getVisitors(page: page, pageSize: pageSize);
  }

  @override
  Future<VisitorEntity> createVisitor(VisitorEntity visitor) => _remote.createVisitor(visitor);

  @override
  Future<VisitorEntity> updateVisitor(int id, VisitorEntity visitor) => _remote.updateVisitor(id, visitor);

  @override
  Future<void> deleteVisitor(int id) => _remote.deleteVisitor(id);

  @override
  Future<PaginatedResult<ComplaintEntity>> getComplaints({int page = 1, int pageSize = 10, String? search}) {
    return _remote.getComplaints(page: page, pageSize: pageSize);
  }

  @override
  Future<ComplaintEntity> createComplaint(ComplaintEntity complaint) => _remote.createComplaint(complaint);

  @override
  Future<ComplaintEntity> updateComplaint(int id, ComplaintEntity complaint) =>
      _remote.updateComplaint(id, complaint);

  @override
  Future<void> deleteComplaint(int id) => _remote.deleteComplaint(id);

  @override
  Future<PaginatedResult<PhoneCallEntity>> getPhoneCalls({int page = 1, int pageSize = 10, String? search}) {
    return _remote.getPhoneCalls(page: page, pageSize: pageSize);
  }

  @override
  Future<PhoneCallEntity> createPhoneCall(PhoneCallEntity call) => _remote.createPhoneCall(call);

  @override
  Future<PhoneCallEntity> updatePhoneCall(int id, PhoneCallEntity call) => _remote.updatePhoneCall(id, call);

  @override
  Future<void> deletePhoneCall(int id) => _remote.deletePhoneCall(id);

  @override
  Future<PaginatedResult<AdminSetupEntity>> getAdminSetups({required String type, int page = 1, int pageSize = 5}) {
    return _remote.getAdminSetups(type: type, page: page, pageSize: pageSize);
  }

  @override
  Future<AdminSetupEntity> createAdminSetup(AdminSetupEntity entry) => _remote.createAdminSetup(entry);

  @override
  Future<AdminSetupEntity> updateAdminSetup(int id, AdminSetupEntity entry) =>
      _remote.updateAdminSetup(id, entry);

  @override
  Future<void> deleteAdminSetup(int id) => _remote.deleteAdminSetup(id);

  @override
  Future<PaginatedResult<PostalReceiveEntity>> getPostalReceives({int page = 1, int pageSize = 10}) {
    return _remote.getPostalReceives(page: page, pageSize: pageSize);
  }

  @override
  Future<PostalReceiveEntity> createPostalReceive(PostalReceiveEntity entry) => _remote.createPostalReceive(entry);

  @override
  Future<PostalReceiveEntity> updatePostalReceive(int id, PostalReceiveEntity entry) =>
      _remote.updatePostalReceive(id, entry);

  @override
  Future<void> deletePostalReceive(int id) => _remote.deletePostalReceive(id);

  @override
  Future<PaginatedResult<PostalDispatchEntity>> getPostalDispatches({int page = 1, int pageSize = 10}) {
    return _remote.getPostalDispatches(page: page, pageSize: pageSize);
  }

  @override
  Future<PostalDispatchEntity> createPostalDispatch(PostalDispatchEntity entry) => _remote.createPostalDispatch(entry);

  @override
  Future<PostalDispatchEntity> updatePostalDispatch(int id, PostalDispatchEntity entry) =>
      _remote.updatePostalDispatch(id, entry);

  @override
  Future<void> deletePostalDispatch(int id) => _remote.deletePostalDispatch(id);

  @override
  Future<PaginatedResult<StudentCategoryEntity>> getStudentCategories({int page = 1, int pageSize = 10, String? status}) {
    return _remote.getStudentCategories(page: page, pageSize: pageSize, status: status);
  }

  @override
  Future<StudentCategoryEntity> createStudentCategory(StudentCategoryEntity category) =>
      _remote.createStudentCategory(category);

  @override
  Future<StudentCategoryEntity> updateStudentCategory(int id, StudentCategoryEntity category) =>
      _remote.updateStudentCategory(id, category);

  @override
  Future<void> deleteStudentCategory(int id) => _remote.deleteStudentCategory(id);
}
