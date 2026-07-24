import '../../domain/models/fees_home_data.dart';
import '../../domain/models/fees_payment.dart';
import '../../domain/models/fees_student_ref.dart';
import '../../domain/models/fees_summary.dart';
import '../../domain/repositories/fees_repository.dart';
import '../datasources/fees_remote_datasource.dart';

class FeesRepositoryImpl implements FeesRepository {
  final FeesRemoteDataSource _remote;
  FeesRepositoryImpl(this._remote);

  @override
  Future<FeesSummary> fetchAssignmentsSummary() => _remote.fetchAssignmentsSummary();

  @override
  Future<FeesHomeData> fetchHomeDashboard() => _remote.fetchHomeDashboard();

  @override
  Future<List<FeesPayment>> fetchPayments() => _remote.fetchPayments();

  @override
  Future<List<FeesStudentRef>> fetchStudents() => _remote.fetchStudents();
}
