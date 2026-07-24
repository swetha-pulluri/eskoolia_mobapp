import '../../domain/models/assignment_student.dart';
import '../../domain/models/fee_assignment.dart';
import '../../domain/repositories/fees_assignment_repository.dart';
import '../datasources/fees_assignment_remote_datasource.dart';

class FeesAssignmentRepositoryImpl implements FeesAssignmentRepository {
  final FeesAssignmentRemoteDataSource _remote;
  FeesAssignmentRepositoryImpl(this._remote);

  @override
  Future<List<AssignmentStudent>> fetchStudents({int? academicYear}) => _remote.fetchStudents(academicYear: academicYear);

  @override
  Future<List<FeeAssignment>> fetchAssignments({int? academicYear}) => _remote.fetchAssignments(academicYear: academicYear);

  Map<String, dynamic> _body({
    required int academicYear,
    required int student,
    required int feesType,
    required String amount,
    required String discountAmount,
    required String concessionAmount,
    String? dueDate,
  }) {
    return {
      'academic_year': academicYear,
      'student': student,
      'fees_type': feesType,
      'amount': amount,
      'discount_amount': discountAmount,
      'concession_amount': concessionAmount,
      'due_date': ?dueDate,
    };
  }

  @override
  Future<FeeAssignment> createAssignment({
    required int academicYear,
    required int student,
    required int feesType,
    required String amount,
    String discountAmount = '0.00',
    String concessionAmount = '0.00',
    String? dueDate,
  }) {
    return _remote.createAssignment(_body(
      academicYear: academicYear,
      student: student,
      feesType: feesType,
      amount: amount,
      discountAmount: discountAmount,
      concessionAmount: concessionAmount,
      dueDate: dueDate,
    ));
  }

  @override
  Future<FeeAssignment> updateAssignment(
    int id, {
    required int academicYear,
    required int student,
    required int feesType,
    required String amount,
    String discountAmount = '0.00',
    String concessionAmount = '0.00',
    String? dueDate,
  }) {
    return _remote.updateAssignment(
      id,
      _body(
        academicYear: academicYear,
        student: student,
        feesType: feesType,
        amount: amount,
        discountAmount: discountAmount,
        concessionAmount: concessionAmount,
        dueDate: dueDate,
      ),
    );
  }
}
