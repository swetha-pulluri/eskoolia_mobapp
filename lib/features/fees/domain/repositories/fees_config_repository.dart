import '../../../student/domain/models/academic_year.dart';
import '../../../student/domain/models/school_class.dart';
import '../models/concession_rule.dart';
import '../models/fee_group.dart';
import '../models/fee_schedule.dart';
import '../models/fee_type.dart';
import '../models/late_fee_rule.dart';
import '../models/term_settings.dart';

/// Thrown by create/update calls that fail validation — `fieldErrors` is
/// keyed by API field name (already unwrapped from whichever error envelope
/// that endpoint uses — see fees_config_remote_datasource.dart).
class FeesConfigValidationException implements Exception {
  final Map<String, String> fieldErrors;
  final String message;
  FeesConfigValidationException(this.fieldErrors, this.message);
}

/// Seam over every resource the Fee Configuration screen manages.
/// Reference: frontend components/fees/FeeConfigurationPanel.tsx.
abstract class FeesConfigRepository {
  Future<List<AcademicYear>> fetchAcademicYears();
  Future<List<SchoolClass>> fetchClasses();

  // Fee Groups
  Future<List<FeesGroup>> fetchGroups();
  Future<FeesGroup> createGroup({
    required int academicYear,
    required String name,
    String? description,
    required List<int> applicableClasses,
    required bool isActive,
  });
  Future<FeesGroup> updateGroup(
    int id, {
    String? name,
    String? description,
    List<int>? applicableClasses,
    bool? isActive,
  });
  Future<void> deleteGroup(int id);

  // Fee Types
  Future<({List<FeesType> rows, int count})> fetchTypes({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String sortBy = 'name',
    String sortDir = 'asc',
  });
  Future<FeesType> createType({
    required int academicYear,
    int? feesGroup,
    required String name,
    required String glCode,
    required String taxable,
    required String defaultStructure,
    required String status,
  });
  Future<FeesType> updateType(
    int id, {
    int? feesGroup,
    required String name,
    required String glCode,
    required String taxable,
    required String defaultStructure,
    required String status,
  });
  Future<void> deleteType(int id);

  // Term Settings
  Future<List<TermSettings>> fetchTermSettings();
  /// Bulk-replaces every term for [academicYear] — any existing term not
  /// present in [terms] is deleted server-side. Always pass the complete
  /// desired term list, never a partial diff.
  Future<List<TermSettings>> saveTermSettings(List<TermSettings> terms);

  // Fee Schedules
  Future<({List<FeeSchedule> rows, int count})> fetchSchedules({
    required int page,
    required int pageSize,
    String? search,
    String? status,
  });
  Future<FeeSchedule> createSchedule({
    required int academicYear,
    int? feeGroup,
    required int feeType,
    required String amount,
    required String collectionFrequency,
    required String dueDate,
    required bool lateFeeApplicable,
    required int gracePeriod,
    required String lateFeeRule,
    required List<TermBreakdownSlot> termBreakdown,
    required String status,
  });
  Future<FeeSchedule> updateSchedule(
    int id, {
    int? academicYear,
    int? feeGroup,
    int? feeType,
    required String amount,
    required String collectionFrequency,
    required String dueDate,
    required bool lateFeeApplicable,
    required int gracePeriod,
    required String lateFeeRule,
    required List<TermBreakdownSlot> termBreakdown,
    required String status,
  });
  Future<void> deleteSchedule(int id);

  // Concession Rules
  Future<List<ConcessionRule>> fetchConcessionRules();
  Future<ConcessionRule> createConcessionRule({
    required String name,
    required String appliesTo,
    required String discountPercentage,
    required String status,
  });
  Future<ConcessionRule> updateConcessionRule(
    int id, {
    required String name,
    required String appliesTo,
    required String discountPercentage,
    required String status,
  });
  Future<void> deleteConcessionRule(int id);

  // Late Fee Rules
  Future<List<LateFeeRule>> fetchLateFeeRules();
  Future<LateFeeRule> createLateFeeRule({
    required String name,
    required int gracePeriodDays,
    required String penaltyRule,
    String? capAmount,
  });
  Future<LateFeeRule> updateLateFeeRule(
    int id, {
    required String name,
    required int gracePeriodDays,
    required String penaltyRule,
    String? capAmount,
  });
  Future<void> deleteLateFeeRule(int id);
}
