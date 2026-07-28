import '../../domain/models/year_end_fee_amount_row.dart';
import '../../domain/repositories/fees_year_end_repository.dart';
import '../datasources/fees_year_end_remote_datasource.dart';

class FeesYearEndRepositoryImpl implements FeesYearEndRepository {
  final FeesYearEndRemoteDataSource _remote;
  FeesYearEndRepositoryImpl(this._remote);

  @override
  Future<List<YearEndFeeAmountRow>> fetchGroupAmounts(int groupId) => _remote.fetchGroupAmounts(groupId);

  @override
  Future<void> saveGroupAmounts(int groupId, List<YearEndFeeAmountRow> rows) {
    return _remote.saveGroupAmounts({
      'group_id': groupId,
      'amounts': [for (final r in rows) {'fee_type_id': r.id, 'new_amount': r.newAmount}],
    });
  }

  @override
  Future<List<int>> fetchReportCsv(String reportType) => _remote.fetchReportCsv(reportType);
}
