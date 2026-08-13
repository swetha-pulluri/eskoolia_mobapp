import '../../domain/entities/leave_policy_entity.dart';
import '../../domain/repositories/leave_policy_repository.dart';
import '../datasources/leave_policy_remote_datasource.dart';

class LeavePolicyRepositoryImpl implements LeavePolicyRepository {
  final LeavePolicyRemoteDataSource _remoteDataSource;

  LeavePolicyRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<LeavePolicyEntity>> getPolicies() => _remoteDataSource.getPolicies();

  @override
  Future<LeavePolicyEntity> createPolicy(Map<String, dynamic> payload) =>
      _remoteDataSource.createPolicy(payload);

  @override
  Future<LeavePolicyEntity> updatePolicy(int id, Map<String, dynamic> payload) =>
      _remoteDataSource.updatePolicy(id, payload);

  @override
  Future<void> deletePolicy(int id) => _remoteDataSource.deletePolicy(id);

  @override
  Future<List<LeaveAuditEntry>> getAuditLog(int objectId) => _remoteDataSource.getAuditLog(objectId);

  @override
  Future<List<Map<String, dynamic>>> previewCarryForward(int fromYear, int toYear) =>
      _remoteDataSource.previewCarryForward(fromYear, toYear);

  @override
  Future<Map<String, dynamic>> runCarryForward(int fromYear, int toYear) =>
      _remoteDataSource.runCarryForward(fromYear, toYear);

  @override
  Future<List<Map<String, dynamic>>> getCarryForwardHistory() => _remoteDataSource.getCarryForwardHistory();
}
