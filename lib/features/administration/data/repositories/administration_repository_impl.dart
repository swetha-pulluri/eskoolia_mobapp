import '../../domain/entities/visitor_entity.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/phone_call_entity.dart';
import '../../domain/entities/admin_setup_entity.dart';
import '../../domain/entities/postal_entity.dart';
import '../../domain/entities/student_category_entity.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/id_card_entity.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/repositories/administration_repository.dart';
import '../datasources/administration_remote_datasource.dart';

class AdministrationRepositoryImpl implements AdministrationRepository {
  final AdministrationRemoteDataSource _remote;

  AdministrationRepositoryImpl(this._remote);

  @override
  Future<PaginatedResult<VisitorEntity>> getVisitors({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? purpose,
    String? date,
  }) {
    return _remote.getVisitors(page: page, pageSize: pageSize, search: search, purpose: purpose, date: date);
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
  Future<PaginatedResult<AdminSetupEntity>> getAdminSetupsUnfiltered() => _remote.getAdminSetupsUnfiltered();

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
  Future<PaginatedResult<StudentCategoryEntity>> getStudentCategories({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? search,
    bool attention = false,
  }) {
    return _remote.getStudentCategories(page: page, pageSize: pageSize, status: status, search: search, attention: attention);
  }

  @override
  Future<StudentCategoryEntity> createStudentCategory(StudentCategoryEntity category) =>
      _remote.createStudentCategory(category);

  @override
  Future<StudentCategoryEntity> updateStudentCategory(int id, StudentCategoryEntity category) =>
      _remote.updateStudentCategory(id, category);

  @override
  Future<void> deleteStudentCategory(int id) => _remote.deleteStudentCategory(id);

  @override
  Future<StudentCategorySummary> getStudentCategorySummary({String? search}) =>
      _remote.getStudentCategorySummary(search: search);

  @override
  Future<bool> checkStudentCategoryNameExists(String name, {int? excludeId}) =>
      _remote.checkStudentCategoryNameExists(name, excludeId: excludeId);

  @override
  Future<String> bulkUpdateStudentCategoryStatus(List<int> ids, String status) =>
      _remote.bulkUpdateStudentCategoryStatus(ids, status);

  @override
  Future<String> bulkDeleteStudentCategories(List<int> ids) => _remote.bulkDeleteStudentCategories(ids);

  @override
  Future<PaginatedResult<IdCardTemplateEntity>> getIdCardTemplates({int page = 1, int pageSize = 10}) =>
      _remote.getIdCardTemplates(page: page, pageSize: pageSize);

  @override
  Future<IdCardTemplateEntity> createIdCardTemplate(IdCardTemplateEntity entry) => _remote.createIdCardTemplate(entry);

  @override
  Future<IdCardTemplateEntity> updateIdCardTemplate(int id, IdCardTemplateEntity entry) =>
      _remote.updateIdCardTemplate(id, entry);

  @override
  Future<void> deleteIdCardTemplate(int id) => _remote.deleteIdCardTemplate(id);

  @override
  Future<DocumentGenerateSetup> getIdCardGenerateSetup() => _remote.getIdCardGenerateSetup();

  @override
  Future<RecipientsResult> getIdCardRecipients({required int role, int? classId, int? sectionId}) =>
      _remote.getIdCardRecipients(role: role, classId: classId, sectionId: sectionId);

  @override
  Future<PaginatedResult<CertificateTemplateEntity>> getCertificateTemplates({int page = 1, int pageSize = 10}) =>
      _remote.getCertificateTemplates(page: page, pageSize: pageSize);

  @override
  Future<CertificateTemplateEntity> createCertificateTemplate(CertificateTemplateEntity entry) =>
      _remote.createCertificateTemplate(entry);

  @override
  Future<CertificateTemplateEntity> updateCertificateTemplate(int id, CertificateTemplateEntity entry) =>
      _remote.updateCertificateTemplate(id, entry);

  @override
  Future<void> deleteCertificateTemplate(int id) => _remote.deleteCertificateTemplate(id);

  @override
  Future<DocumentGenerateSetup> getCertificateGenerateSetup() => _remote.getCertificateGenerateSetup();

  @override
  Future<RecipientsResult> getCertificateRecipients({required int role, int? classId, int? sectionId}) =>
      _remote.getCertificateRecipients(role: role, classId: classId, sectionId: sectionId);

  @override
  Future<List<RoleEntity>> getRoles() => _remote.getRoles();
}
