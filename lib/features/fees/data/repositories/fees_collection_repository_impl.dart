import '../../domain/models/fees_payment.dart';
import '../../domain/models/fees_reconciliation.dart';
import '../../domain/models/school_header_info.dart';
import '../../domain/repositories/fees_collection_repository.dart';
import '../datasources/fees_collection_remote_datasource.dart';

class FeesCollectionRepositoryImpl implements FeesCollectionRepository {
  final FeesCollectionRemoteDataSource _remote;
  FeesCollectionRepositoryImpl(this._remote);

  @override
  Future<FeesPayment> createPayment({
    required int assignment,
    required String amountPaid,
    required String method,
    required String paidAt,
    String? note,
  }) {
    return _remote.createPayment({
      'assignment': assignment,
      'amount_paid': amountPaid,
      'method': method,
      'paid_at': paidAt,
      'note': note ?? '',
    });
  }

  @override
  Future<List<FeesReconciliation>> fetchReconciliations() => _remote.fetchReconciliations();

  @override
  Future<FeesReconciliation> createReconciliation(FeesReconciliation draft) {
    return _remote.createReconciliation(draft.toCreateJson());
  }

  @override
  Future<SchoolHeaderInfo> fetchMySchoolInfo() => _remote.fetchMySchoolInfo();
}
