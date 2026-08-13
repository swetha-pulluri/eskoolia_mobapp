import '../../domain/entities/school_info_entity.dart';
import '../../domain/repositories/school_info_repository.dart';
import '../datasources/school_info_remote_datasource.dart';

class SchoolInfoRepositoryImpl implements SchoolInfoRepository {
  final SchoolInfoRemoteDataSource _remoteDataSource;

  SchoolInfoRepositoryImpl(this._remoteDataSource);

  @override
  Future<SchoolInfoEntity> getSchoolInfo() => _remoteDataSource.getSchoolInfo();

  @override
  Future<SchoolInfoEntity> updateSchoolInfo(Map<String, dynamic> payload) =>
      _remoteDataSource.updateSchoolInfo(payload);

  @override
  Future<SchoolInfoEntity> uploadLogo(List<int> bytes, String filename, String mimeType) =>
      _remoteDataSource.uploadLogo(bytes, filename, mimeType);
}
