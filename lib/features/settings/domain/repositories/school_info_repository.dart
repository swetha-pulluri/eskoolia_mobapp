import '../entities/school_info_entity.dart';

/// Settings → School Info wizard — backed by the live singleton endpoint
/// `/api/v1/settings/school-info/` (backend/apps/settings/views.py::
/// SchoolInfoView) plus its logo sub-route.
abstract class SchoolInfoRepository {
  Future<SchoolInfoEntity> getSchoolInfo();

  Future<SchoolInfoEntity> updateSchoolInfo(Map<String, dynamic> payload);

  Future<SchoolInfoEntity> uploadLogo(List<int> bytes, String filename, String mimeType);
}
