import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../student/domain/models/academic_year.dart';
import '../../../student/domain/models/school_class.dart';
import '../../domain/models/concession_rule.dart';
import '../../domain/models/fee_group.dart';
import '../../domain/models/fee_schedule.dart';
import '../../domain/models/fee_type.dart';
import '../../domain/models/late_fee_rule.dart';
import '../../domain/models/term_settings.dart';
import '../../domain/repositories/fees_config_repository.dart' show FeesConfigValidationException;

/// Extracts a list from either a bare array or a paginated
/// `{count, next, previous, results}` body.
List<dynamic> listData(dynamic body) {
  if (body is List) return body;
  if (body is Map<String, dynamic>) {
    final results = body['results'];
    if (results is List) return results;
  }
  return const [];
}

int totalCountOf(dynamic body, int fallback) {
  if (body is Map<String, dynamic> && body['count'] is int) return body['count'] as int;
  return fallback;
}

/// Every `apps/fees` resource uses one of two 400 error shapes: Fee Groups
/// and Fee Types return bare DRF `{field: [messages]}`; Term Settings, Fee
/// Schedules, Concession Rules, and Late Fee Rules wrap it as
/// `{success, message, errors: {field: [messages]}}`. This unwraps either.
Map<String, String> _fieldErrors(dynamic data) {
  if (data is! Map) return {};
  final map = Map<String, dynamic>.from(data);
  final errors = map['errors'] is Map ? Map<String, dynamic>.from(map['errors'] as Map) : map;
  final result = <String, String>{};
  errors.forEach((key, value) {
    if (key == 'success' || key == 'message') return;
    if (value is List && value.isNotEmpty) {
      result[key] = value.first.toString();
    } else if (value is String) {
      result[key] = value;
    }
  });
  return result;
}

String _topMessage(dynamic data, String fallback) {
  if (data is Map && data['message'] is String) return data['message'] as String;
  final fieldErrors = _fieldErrors(data);
  if (fieldErrors.isNotEmpty) return fieldErrors.values.first;
  return fallback;
}

Never _throwValidation(DioException e, String fallback) {
  final data = e.response?.data;
  throw FeesConfigValidationException(_fieldErrors(data), _topMessage(data, fallback));
}

abstract class FeesConfigRemoteDataSource {
  Future<List<AcademicYear>> fetchAcademicYears();
  Future<List<SchoolClass>> fetchClasses();

  Future<List<FeesGroup>> fetchGroups();
  Future<FeesGroup> createGroup(Map<String, dynamic> body);
  Future<FeesGroup> updateGroup(int id, Map<String, dynamic> body);
  Future<void> deleteGroup(int id);

  Future<({List<FeesType> rows, int count})> fetchTypes(Map<String, dynamic> query);
  Future<FeesType> createType(Map<String, dynamic> body);
  Future<FeesType> updateType(int id, Map<String, dynamic> body);
  Future<void> deleteType(int id);

  Future<List<TermSettings>> fetchTermSettings();
  Future<List<TermSettings>> saveTermSettings(List<Map<String, dynamic>> body);

  Future<({List<FeeSchedule> rows, int count})> fetchSchedules(Map<String, dynamic> query);
  Future<FeeSchedule> createSchedule(Map<String, dynamic> body);
  Future<FeeSchedule> updateSchedule(int id, Map<String, dynamic> body);
  Future<void> deleteSchedule(int id);

  Future<List<ConcessionRule>> fetchConcessionRules();
  Future<ConcessionRule> createConcessionRule(Map<String, dynamic> body);
  Future<ConcessionRule> updateConcessionRule(int id, Map<String, dynamic> body);
  Future<void> deleteConcessionRule(int id);

  Future<List<LateFeeRule>> fetchLateFeeRules();
  Future<LateFeeRule> createLateFeeRule(Map<String, dynamic> body);
  Future<LateFeeRule> updateLateFeeRule(int id, Map<String, dynamic> body);
  Future<void> deleteLateFeeRule(int id);
}

class FeesConfigRemoteDataSourceImpl implements FeesConfigRemoteDataSource {
  final Dio _dio;
  FeesConfigRemoteDataSourceImpl(this._dio);

  @override
  Future<List<AcademicYear>> fetchAcademicYears() async {
    final response = await _dio.get(ApiConstants.coreAcademicYears, queryParameters: {'page_size': 500});
    return listData(response.data).map((e) => AcademicYear.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<SchoolClass>> fetchClasses() async {
    final response = await _dio.get(ApiConstants.coreClasses, queryParameters: {'page_size': 500});
    return listData(response.data).map((e) => SchoolClass.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Fee Groups ── (bare DRF error shape)

  @override
  Future<List<FeesGroup>> fetchGroups() async {
    final response = await _dio.get(ApiConstants.feesGroups, queryParameters: {'page_size': 500});
    return listData(response.data).map((e) => FeesGroup.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<FeesGroup> createGroup(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.feesGroups, data: body);
      return FeesGroup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to save fee group.');
    }
  }

  @override
  Future<FeesGroup> updateGroup(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(ApiConstants.feesGroupDetail(id), data: body);
      return FeesGroup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to update fee group.');
    }
  }

  @override
  Future<void> deleteGroup(int id) async {
    try {
      await _dio.delete(ApiConstants.feesGroupDetail(id));
    } on DioException catch (e) {
      final message = (e.response?.data is Map ? (e.response?.data['message'] as String?) : null) ??
          'This fee group could not be deleted. Please try again.';
      throw FeesConfigValidationException({}, message);
    }
  }

  // ── Fee Types ── (bare DRF error shape)

  @override
  Future<({List<FeesType> rows, int count})> fetchTypes(Map<String, dynamic> query) async {
    final response = await _dio.get(ApiConstants.feesTypes, queryParameters: query);
    final rows = listData(response.data).map((e) => FeesType.fromJson(e as Map<String, dynamic>)).toList();
    return (rows: rows, count: totalCountOf(response.data, rows.length));
  }

  @override
  Future<FeesType> createType(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.feesTypes, data: body);
      return FeesType.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to create fee type.');
    }
  }

  @override
  Future<FeesType> updateType(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(ApiConstants.feesTypeDetail(id), data: body);
      return FeesType.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to update fee type.');
    }
  }

  @override
  Future<void> deleteType(int id) async {
    try {
      await _dio.delete(ApiConstants.feesTypeDetail(id));
    } on DioException catch (e) {
      final message = (e.response?.data is Map ? (e.response?.data['message'] as String?) : null) ??
          'This fee type could not be deleted.';
      throw FeesConfigValidationException({}, message);
    }
  }

  // ── Term Settings ── ({success,message,errors} error shape)

  @override
  Future<List<TermSettings>> fetchTermSettings() async {
    final response = await _dio.get(ApiConstants.feesTermSettings, queryParameters: {'page_size': 500});
    return listData(response.data).map((e) => TermSettings.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TermSettings>> saveTermSettings(List<Map<String, dynamic>> body) async {
    try {
      final response = await _dio.post(ApiConstants.feesTermSettings, data: body);
      final data = response.data;
      final list = data is List ? data : listData(data);
      return list.map((e) => TermSettings.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to save term settings.');
    }
  }

  // ── Fee Schedules ── ({success,message,errors} error shape)

  @override
  Future<({List<FeeSchedule> rows, int count})> fetchSchedules(Map<String, dynamic> query) async {
    final response = await _dio.get(ApiConstants.feesSchedules, queryParameters: query);
    final rows = listData(response.data).map((e) => FeeSchedule.fromJson(e as Map<String, dynamic>)).toList();
    return (rows: rows, count: totalCountOf(response.data, rows.length));
  }

  @override
  Future<FeeSchedule> createSchedule(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.feesSchedules, data: body);
      return FeeSchedule.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to create fee schedule.');
    }
  }

  @override
  Future<FeeSchedule> updateSchedule(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(ApiConstants.feesScheduleDetail(id), data: body);
      return FeeSchedule.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to update fee schedule.');
    }
  }

  @override
  Future<void> deleteSchedule(int id) async {
    try {
      await _dio.delete(ApiConstants.feesScheduleDetail(id));
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to delete fee schedule.');
    }
  }

  // ── Concession Rules ── ({success,message,errors} error shape)

  @override
  Future<List<ConcessionRule>> fetchConcessionRules() async {
    final response = await _dio.get(ApiConstants.feesConcessionRules, queryParameters: {'page_size': 100});
    return listData(response.data).map((e) => ConcessionRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ConcessionRule> createConcessionRule(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.feesConcessionRules, data: body);
      return ConcessionRule.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to save concession rule.');
    }
  }

  @override
  Future<ConcessionRule> updateConcessionRule(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(ApiConstants.feesConcessionRuleDetail(id), data: body);
      return ConcessionRule.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to save concession rule.');
    }
  }

  @override
  Future<void> deleteConcessionRule(int id) async {
    try {
      await _dio.delete(ApiConstants.feesConcessionRuleDetail(id));
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to delete concession rule.');
    }
  }

  // ── Late Fee Rules ── ({success,message,errors} error shape)

  @override
  Future<List<LateFeeRule>> fetchLateFeeRules() async {
    final response = await _dio.get(ApiConstants.feesLateFeeRules, queryParameters: {'page_size': 100});
    return listData(response.data).map((e) => LateFeeRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<LateFeeRule> createLateFeeRule(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.feesLateFeeRules, data: body);
      return LateFeeRule.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to save late fee rule.');
    }
  }

  @override
  Future<LateFeeRule> updateLateFeeRule(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(ApiConstants.feesLateFeeRuleDetail(id), data: body);
      return LateFeeRule.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to save late fee rule.');
    }
  }

  @override
  Future<void> deleteLateFeeRule(int id) async {
    try {
      await _dio.delete(ApiConstants.feesLateFeeRuleDetail(id));
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to delete late fee rule.');
    }
  }
}
