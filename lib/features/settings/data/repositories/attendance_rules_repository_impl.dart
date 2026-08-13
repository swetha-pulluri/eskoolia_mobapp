import '../../domain/entities/attendance_policy_entity.dart';
import '../../domain/repositories/attendance_rules_repository.dart';
import '../datasources/attendance_rules_remote_datasource.dart';

class AttendanceRulesRepositoryImpl implements AttendanceRulesRepository {
  final AttendanceRulesRemoteDataSource _dataSource;

  AttendanceRulesRepositoryImpl(this._dataSource);

  @override
  Future<List<AttendancePolicyEntity>> getPolicies() => _dataSource.getPolicies();

  @override
  Future<AttendancePolicyEntity> createPolicy(Map<String, dynamic> payload) => _dataSource.createPolicy(payload);

  @override
  Future<AttendancePolicyEntity> updatePolicy(int id, Map<String, dynamic> payload) =>
      _dataSource.updatePolicy(id, payload);

  @override
  Future<void> deletePolicy(int id) => _dataSource.deletePolicy(id);

  @override
  Future<AttendancePolicyEntity> makeDefault(int id) => _dataSource.makeDefault(id);

  @override
  Future<List<AttendanceAuditEntry>> getAuditLog(int objectId) => _dataSource.getAuditLog(objectId);
}
