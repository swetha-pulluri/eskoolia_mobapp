import '../../domain/models/due_interaction.dart';
import '../../domain/models/dues_class_group.dart';
import '../../domain/models/dues_summary.dart';
import '../../domain/repositories/fees_dues_repository.dart';
import '../datasources/fees_dues_remote_datasource.dart';

class FeesDuesRepositoryImpl implements FeesDuesRepository {
  final FeesDuesRemoteDataSource _remote;
  FeesDuesRepositoryImpl(this._remote);

  @override
  Future<List<DuesClassGroup>> fetchByClass({required int tier}) => _remote.fetchByClass(tier: tier);

  @override
  Future<DuesSummary> fetchSummary() => _remote.fetchSummary();

  @override
  Future<List<DueInteraction>> fetchInteractions(String studentId) => _remote.fetchInteractions(studentId);

  @override
  Future<DueInteraction> createInteraction({
    required String student,
    required String note,
    String? agreedAmount,
    String? agreedDate,
  }) {
    return _remote.createInteraction({
      'student': student,
      'interaction_type': 'note',
      'note': note,
      if (agreedAmount != null && agreedAmount.isNotEmpty) 'agreed_amount': agreedAmount,
      if (agreedDate != null && agreedDate.isNotEmpty) 'agreed_date': agreedDate,
    });
  }

  @override
  Future<DueInteraction> resolveDue(String studentId, {String? note}) {
    return _remote.resolveDue({
      'student_id': studentId,
      if (note != null) 'note': note,
    });
  }

  @override
  Future<int> sendReminders(List<String> studentIds, String message) {
    return _remote.sendReminders({'student_ids': studentIds, 'message': message});
  }

  @override
  Future<List<int>> exportCsv() => _remote.exportCsv();
}
