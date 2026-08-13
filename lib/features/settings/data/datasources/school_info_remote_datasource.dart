import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/school_info_entity.dart';

/// Reference: backend/apps/settings/{urls,views}.py (SchoolInfoView,
/// SchoolInfoLogoUploadView), frontend/components/settings/SchoolInfoPanel.tsx.
class SchoolInfoRemoteDataSource {
  final DioClient _dioClient;

  SchoolInfoRemoteDataSource(this._dioClient);

  Future<SchoolInfoEntity> getSchoolInfo() async {
    final response = await _dioClient.get(ApiConstants.settingsSchoolInfo);
    return SchoolInfoEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SchoolInfoEntity> updateSchoolInfo(Map<String, dynamic> payload) async {
    final response = await _dioClient.patch(ApiConstants.settingsSchoolInfo, data: payload);
    return SchoolInfoEntity.fromJson(response.data as Map<String, dynamic>);
  }

  /// Field name is `file` — confirmed from SchoolInfoLogoUploadView.post(),
  /// not `logo` like the unrelated school_tenancy upload endpoint.
  Future<SchoolInfoEntity> uploadLogo(List<int> bytes, String filename, String mimeType) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    });
    final response = await _dioClient.post(ApiConstants.settingsSchoolInfoLogo, data: formData);
    return SchoolInfoEntity.fromJson(response.data as Map<String, dynamic>);
  }
}
