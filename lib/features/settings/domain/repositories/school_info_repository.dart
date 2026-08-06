import '../entities/school_info_entity.dart';

abstract class SchoolInfoRepository {
  /// GET `/api/v1/tenancy/my-school-info/` — school-scoped, read-only.
  Future<SchoolInfoEntity> getMySchoolInfo();
}
