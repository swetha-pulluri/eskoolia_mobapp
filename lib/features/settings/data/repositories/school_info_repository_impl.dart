import '../../domain/entities/school_info_entity.dart';
import '../../domain/repositories/school_info_repository.dart';
import '../datasources/school_info_remote_datasource.dart';

class SchoolInfoRepositoryImpl implements SchoolInfoRepository {
  final SchoolInfoRemoteDataSource _remoteDataSource;

  SchoolInfoRepositoryImpl(this._remoteDataSource);

  @override
  Future<SchoolInfoEntity> getMySchoolInfo() => _remoteDataSource.getMySchoolInfo();
}
