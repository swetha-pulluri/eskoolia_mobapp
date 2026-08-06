import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/school_info_entity.dart';

class SchoolInfoRemoteDataSource {
  final DioClient _dioClient;

  SchoolInfoRemoteDataSource(this._dioClient);

  Future<SchoolInfoEntity> getMySchoolInfo() async {
    final response = await _dioClient.get(ApiConstants.tenancyMySchoolInfo);
    return SchoolInfoEntity.fromJson(response.data as Map<String, dynamic>);
  }
}
