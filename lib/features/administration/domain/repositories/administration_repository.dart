import '../entities/visitor_entity.dart';
import '../entities/complaint_entity.dart';
import '../entities/phone_call_entity.dart';
import '../entities/admin_setup_entity.dart';
import '../entities/postal_entity.dart';
import '../entities/student_category_entity.dart';
import '../entities/paginated_result.dart';

/// Administration Repository — Communication Hub, Postal Management,
/// Documents Studio and System Config data access.
abstract class AdministrationRepository {
  // Visitor Book
  Future<PaginatedResult<VisitorEntity>> getVisitors({
    int page,
    int pageSize,
    String? search,
  });
  Future<VisitorEntity> createVisitor(VisitorEntity visitor);
  Future<VisitorEntity> updateVisitor(int id, VisitorEntity visitor);
  Future<void> deleteVisitor(int id);

  // Complaints
  Future<PaginatedResult<ComplaintEntity>> getComplaints({
    int page,
    int pageSize,
    String? search,
  });
  Future<ComplaintEntity> createComplaint(ComplaintEntity complaint);
  Future<ComplaintEntity> updateComplaint(int id, ComplaintEntity complaint);
  Future<void> deleteComplaint(int id);

  // Phone Call Log
  Future<PaginatedResult<PhoneCallEntity>> getPhoneCalls({
    int page,
    int pageSize,
    String? search,
  });
  Future<PhoneCallEntity> createPhoneCall(PhoneCallEntity call);
  Future<PhoneCallEntity> updatePhoneCall(int id, PhoneCallEntity call);
  Future<void> deletePhoneCall(int id);

  // Admin Setup (Purpose / Complaint Type / Source / Reference lookups)
  Future<PaginatedResult<AdminSetupEntity>> getAdminSetups({
    required String type,
    int page,
    int pageSize,
  });
  Future<AdminSetupEntity> createAdminSetup(AdminSetupEntity entry);
  Future<AdminSetupEntity> updateAdminSetup(int id, AdminSetupEntity entry);
  Future<void> deleteAdminSetup(int id);

  // Postal Received
  Future<PaginatedResult<PostalReceiveEntity>> getPostalReceives({int page, int pageSize});
  Future<PostalReceiveEntity> createPostalReceive(PostalReceiveEntity entry);
  Future<PostalReceiveEntity> updatePostalReceive(int id, PostalReceiveEntity entry);
  Future<void> deletePostalReceive(int id);

  // Postal Dispatched
  Future<PaginatedResult<PostalDispatchEntity>> getPostalDispatches({int page, int pageSize});
  Future<PostalDispatchEntity> createPostalDispatch(PostalDispatchEntity entry);
  Future<PostalDispatchEntity> updatePostalDispatch(int id, PostalDispatchEntity entry);
  Future<void> deletePostalDispatch(int id);

  // Student Categories (System Config)
  Future<PaginatedResult<StudentCategoryEntity>> getStudentCategories({int page, int pageSize, String? status});
  Future<StudentCategoryEntity> createStudentCategory(StudentCategoryEntity category);
  Future<StudentCategoryEntity> updateStudentCategory(int id, StudentCategoryEntity category);
  Future<void> deleteStudentCategory(int id);
}
