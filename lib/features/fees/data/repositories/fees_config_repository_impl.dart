import '../../../student/domain/models/academic_year.dart';
import '../../../student/domain/models/school_class.dart';
import '../../domain/models/concession_rule.dart';
import '../../domain/models/fee_group.dart';
import '../../domain/models/fee_schedule.dart';
import '../../domain/models/fee_type.dart';
import '../../domain/models/late_fee_rule.dart';
import '../../domain/models/term_settings.dart';
import '../../domain/repositories/fees_config_repository.dart';
import '../datasources/fees_config_remote_datasource.dart';

class FeesConfigRepositoryImpl implements FeesConfigRepository {
  final FeesConfigRemoteDataSource _remote;
  FeesConfigRepositoryImpl(this._remote);

  @override
  Future<List<AcademicYear>> fetchAcademicYears() => _remote.fetchAcademicYears();

  @override
  Future<List<SchoolClass>> fetchClasses() => _remote.fetchClasses();

  // ── Fee Groups ──

  @override
  Future<List<FeesGroup>> fetchGroups() => _remote.fetchGroups();

  @override
  Future<FeesGroup> createGroup({
    required int academicYear,
    required String name,
    String? description,
    required List<int> applicableClasses,
    required bool isActive,
  }) {
    return _remote.createGroup({
      'academic_year': academicYear,
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'applicable_classes': applicableClasses,
      'is_active': isActive,
    });
  }

  @override
  Future<FeesGroup> updateGroup(
    int id, {
    String? name,
    String? description,
    List<int>? applicableClasses,
    bool? isActive,
  }) {
    return _remote.updateGroup(id, {
      'name': ?name,
      if (description != null && description.isNotEmpty) 'description': description,
      'applicable_classes': ?applicableClasses,
      'is_active': ?isActive,
    });
  }

  @override
  Future<void> deleteGroup(int id) => _remote.deleteGroup(id);

  // ── Fee Types ──

  @override
  Future<({List<FeesType> rows, int count})> fetchTypes({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String sortBy = 'name',
    String sortDir = 'asc',
  }) {
    return _remote.fetchTypes({
      'page': page,
      'page_size': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      'sort_by': sortBy,
      'sort_dir': sortDir,
    });
  }

  @override
  Future<FeesType> createType({
    required int academicYear,
    int? feesGroup,
    required String name,
    required String glCode,
    required String taxable,
    required String defaultStructure,
    required String status,
  }) {
    return _remote.createType({
      'academic_year': academicYear,
      'fees_group': ?feesGroup,
      'name': name,
      'gl_code': glCode,
      'taxable': taxable,
      'default_structure': defaultStructure,
      'status': status,
    });
  }

  @override
  Future<FeesType> updateType(
    int id, {
    int? feesGroup,
    required String name,
    required String glCode,
    required String taxable,
    required String defaultStructure,
    required String status,
  }) {
    return _remote.updateType(id, {
      'fees_group': ?feesGroup,
      'name': name,
      'gl_code': glCode,
      'taxable': taxable,
      'default_structure': defaultStructure,
      'status': status,
    });
  }

  @override
  Future<void> deleteType(int id) => _remote.deleteType(id);

  // ── Term Settings ──

  @override
  Future<List<TermSettings>> fetchTermSettings() => _remote.fetchTermSettings();

  @override
  Future<List<TermSettings>> saveTermSettings(List<TermSettings> terms) {
    return _remote.saveTermSettings(terms.map((t) => t.toJson()).toList());
  }

  // ── Fee Schedules ──

  @override
  Future<({List<FeeSchedule> rows, int count})> fetchSchedules({
    required int page,
    required int pageSize,
    String? search,
    String? status,
  }) {
    return _remote.fetchSchedules({
      'page': page,
      'page_size': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    });
  }

  Map<String, dynamic> _scheduleBody({
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
  }) {
    return {
      'academic_year': ?academicYear,
      'fee_group': feeGroup,
      'fee_type': ?feeType,
      'amount': amount,
      'collection_frequency': collectionFrequency,
      'due_date': dueDate,
      'late_fee_applicable': lateFeeApplicable,
      'grace_period': gracePeriod,
      'late_fee_rule': lateFeeRule,
      'term_breakdown': termBreakdown.map((t) => t.toJson()).toList(),
      'status': status,
    };
  }

  @override
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
  }) {
    return _remote.createSchedule(_scheduleBody(
      academicYear: academicYear,
      feeGroup: feeGroup,
      feeType: feeType,
      amount: amount,
      collectionFrequency: collectionFrequency,
      dueDate: dueDate,
      lateFeeApplicable: lateFeeApplicable,
      gracePeriod: gracePeriod,
      lateFeeRule: lateFeeRule,
      termBreakdown: termBreakdown,
      status: status,
    ));
  }

  @override
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
  }) {
    return _remote.updateSchedule(
      id,
      _scheduleBody(
        academicYear: academicYear,
        feeGroup: feeGroup,
        feeType: feeType,
        amount: amount,
        collectionFrequency: collectionFrequency,
        dueDate: dueDate,
        lateFeeApplicable: lateFeeApplicable,
        gracePeriod: gracePeriod,
        lateFeeRule: lateFeeRule,
        termBreakdown: termBreakdown,
        status: status,
      ),
    );
  }

  @override
  Future<void> deleteSchedule(int id) => _remote.deleteSchedule(id);

  // ── Concession Rules ──

  @override
  Future<List<ConcessionRule>> fetchConcessionRules() => _remote.fetchConcessionRules();

  @override
  Future<ConcessionRule> createConcessionRule({
    required String name,
    required String appliesTo,
    required String discountPercentage,
    required String status,
  }) {
    return _remote.createConcessionRule({
      'name': name,
      'applies_to': appliesTo,
      'discount_percentage': discountPercentage,
      'status': status,
    });
  }

  @override
  Future<ConcessionRule> updateConcessionRule(
    int id, {
    required String name,
    required String appliesTo,
    required String discountPercentage,
    required String status,
  }) {
    return _remote.updateConcessionRule(id, {
      'name': name,
      'applies_to': appliesTo,
      'discount_percentage': discountPercentage,
      'status': status,
    });
  }

  @override
  Future<void> deleteConcessionRule(int id) => _remote.deleteConcessionRule(id);

  // ── Late Fee Rules ──

  @override
  Future<List<LateFeeRule>> fetchLateFeeRules() => _remote.fetchLateFeeRules();

  @override
  Future<LateFeeRule> createLateFeeRule({
    required String name,
    required int gracePeriodDays,
    required String penaltyRule,
    String? capAmount,
  }) {
    return _remote.createLateFeeRule({
      'name': name,
      'grace_period_days': gracePeriodDays,
      'penalty_rule': penaltyRule,
      'cap_amount': capAmount,
      'status': 'Active',
    });
  }

  @override
  Future<LateFeeRule> updateLateFeeRule(
    int id, {
    required String name,
    required int gracePeriodDays,
    required String penaltyRule,
    String? capAmount,
  }) {
    return _remote.updateLateFeeRule(id, {
      'name': name,
      'grace_period_days': gracePeriodDays,
      'penalty_rule': penaltyRule,
      'cap_amount': capAmount,
    });
  }

  @override
  Future<void> deleteLateFeeRule(int id) => _remote.deleteLateFeeRule(id);
}
