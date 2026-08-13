/// Settings → Leave Policy: one `LeaveType` record (identity fields +
/// ~30 policy fields). Reference: backend/apps/hr/models.py::LeaveType,
/// backend/apps/settings/serializers.py::LeavePolicySerializer,
/// frontend/components/settings/LeavePolicyPanel.tsx (`interface LeavePolicy`).
class LeavePolicyEntity {
  final int id;
  final String name;
  final int maxDaysPerYear;
  final bool isPaid;
  final bool isActive;
  final bool isBuiltin;

  final bool canCarryForward;
  final int maxCarryForwardDays;
  final String carryForwardType;
  final int carryForwardExpiryDays;
  final String carryForwardMode;

  final int minimumLeaveDuration;
  final int maximumLeaveDuration;
  final int maximumConsecutiveDays;
  final bool allowHalfDay;
  final bool allowBackdatedLeave;
  final int maximumBackdatedDays;
  final bool allowFutureLeave;
  final int maximumFutureDays;

  final String applicableGender;
  final int minimumServicePeriod;
  final int minimumNoticePeriod;
  final bool allowProbationLeave;
  final bool allowNoticePeriodLeave;
  final List<String> applicableDepartments;
  final List<String> applicableDesignations;
  final List<String> applicableEmploymentTypes;

  final bool attachmentRequired;
  final bool medicalCertificateRequired;
  final int medicalCertificateAfterDays;

  final bool sandwichLeaveEnabled;
  final bool countHolidaysAsLeave;
  final bool countWeekoffsAsLeave;

  final bool allowNegativeBalance;
  final bool convertToLop;
  final bool allowLeaveCancellation;
  final int cancellationAllowedUntil;
  final bool allowLeaveExtension;
  final bool allowLeaveCombination;

  final String policyNote;

  const LeavePolicyEntity({
    required this.id,
    required this.name,
    required this.maxDaysPerYear,
    required this.isPaid,
    required this.isActive,
    required this.isBuiltin,
    required this.canCarryForward,
    required this.maxCarryForwardDays,
    required this.carryForwardType,
    required this.carryForwardExpiryDays,
    required this.carryForwardMode,
    required this.minimumLeaveDuration,
    required this.maximumLeaveDuration,
    required this.maximumConsecutiveDays,
    required this.allowHalfDay,
    required this.allowBackdatedLeave,
    required this.maximumBackdatedDays,
    required this.allowFutureLeave,
    required this.maximumFutureDays,
    required this.applicableGender,
    required this.minimumServicePeriod,
    required this.minimumNoticePeriod,
    required this.allowProbationLeave,
    required this.allowNoticePeriodLeave,
    required this.applicableDepartments,
    required this.applicableDesignations,
    required this.applicableEmploymentTypes,
    required this.attachmentRequired,
    required this.medicalCertificateRequired,
    required this.medicalCertificateAfterDays,
    required this.sandwichLeaveEnabled,
    required this.countHolidaysAsLeave,
    required this.countWeekoffsAsLeave,
    required this.allowNegativeBalance,
    required this.convertToLop,
    required this.allowLeaveCancellation,
    required this.cancellationAllowedUntil,
    required this.allowLeaveExtension,
    required this.allowLeaveCombination,
    required this.policyNote,
  });

  static int _int(Map<String, dynamic> json, String key) => (json[key] as num?)?.toInt() ?? 0;
  static bool _bool(Map<String, dynamic> json, String key, {bool fallback = false}) =>
      json[key] as bool? ?? fallback;
  static List<String> _stringList(Map<String, dynamic> json, String key) =>
      ((json[key] as List?) ?? const []).map((e) => e.toString()).toList();

  factory LeavePolicyEntity.fromJson(Map<String, dynamic> json) {
    return LeavePolicyEntity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      maxDaysPerYear: _int(json, 'max_days_per_year'),
      isPaid: _bool(json, 'is_paid', fallback: true),
      isActive: _bool(json, 'is_active', fallback: true),
      isBuiltin: _bool(json, 'is_builtin'),
      canCarryForward: _bool(json, 'can_carry_forward'),
      maxCarryForwardDays: _int(json, 'max_carry_forward_days'),
      carryForwardType: json['carry_forward_type'] as String? ?? 'limited',
      carryForwardExpiryDays: _int(json, 'carry_forward_expiry_days'),
      carryForwardMode: json['carry_forward_mode'] as String? ?? 'automatic',
      minimumLeaveDuration: _int(json, 'minimum_leave_duration'),
      maximumLeaveDuration: _int(json, 'maximum_leave_duration'),
      maximumConsecutiveDays: _int(json, 'maximum_consecutive_days'),
      allowHalfDay: _bool(json, 'allow_half_day', fallback: true),
      allowBackdatedLeave: _bool(json, 'allow_backdated_leave'),
      maximumBackdatedDays: _int(json, 'maximum_backdated_days'),
      allowFutureLeave: _bool(json, 'allow_future_leave', fallback: true),
      maximumFutureDays: _int(json, 'maximum_future_days'),
      applicableGender: json['applicable_gender'] as String? ?? 'all',
      minimumServicePeriod: _int(json, 'minimum_service_period'),
      minimumNoticePeriod: _int(json, 'minimum_notice_period'),
      allowProbationLeave: _bool(json, 'allow_probation_leave'),
      allowNoticePeriodLeave: _bool(json, 'allow_notice_period_leave', fallback: true),
      applicableDepartments: _stringList(json, 'applicable_departments'),
      applicableDesignations: _stringList(json, 'applicable_designations'),
      applicableEmploymentTypes: _stringList(json, 'applicable_employment_types'),
      attachmentRequired: _bool(json, 'attachment_required'),
      medicalCertificateRequired: _bool(json, 'medical_certificate_required'),
      medicalCertificateAfterDays: _int(json, 'medical_certificate_after_days'),
      sandwichLeaveEnabled: _bool(json, 'sandwich_leave_enabled'),
      countHolidaysAsLeave: _bool(json, 'count_holidays_as_leave'),
      countWeekoffsAsLeave: _bool(json, 'count_weekoffs_as_leave'),
      allowNegativeBalance: _bool(json, 'allow_negative_balance'),
      convertToLop: _bool(json, 'convert_to_lop'),
      allowLeaveCancellation: _bool(json, 'allow_leave_cancellation', fallback: true),
      cancellationAllowedUntil: _int(json, 'cancellation_allowed_until'),
      allowLeaveExtension: _bool(json, 'allow_leave_extension'),
      allowLeaveCombination: _bool(json, 'allow_leave_combination'),
      policyNote: json['policy_note'] as String? ?? '',
    );
  }

  /// Raw per-field map used to seed the wizard's editable `draft` state —
  /// mirrors the web's `setDraft(policy)` on edit / `WIZARD_DEFAULTS` on
  /// create. Keys match the backend field names exactly.
  Map<String, dynamic> toFormMap() {
    return {
      'name': name,
      'max_days_per_year': maxDaysPerYear,
      'is_paid': isPaid,
      'is_active': isActive,
      'can_carry_forward': canCarryForward,
      'max_carry_forward_days': maxCarryForwardDays,
      'carry_forward_type': carryForwardType,
      'carry_forward_expiry_days': carryForwardExpiryDays,
      'carry_forward_mode': carryForwardMode,
      'minimum_leave_duration': minimumLeaveDuration,
      'maximum_leave_duration': maximumLeaveDuration,
      'maximum_consecutive_days': maximumConsecutiveDays,
      'allow_half_day': allowHalfDay,
      'allow_backdated_leave': allowBackdatedLeave,
      'maximum_backdated_days': maximumBackdatedDays,
      'allow_future_leave': allowFutureLeave,
      'maximum_future_days': maximumFutureDays,
      'applicable_gender': applicableGender,
      'minimum_service_period': minimumServicePeriod,
      'minimum_notice_period': minimumNoticePeriod,
      'allow_probation_leave': allowProbationLeave,
      'allow_notice_period_leave': allowNoticePeriodLeave,
      'applicable_departments': List<String>.from(applicableDepartments),
      'applicable_designations': List<String>.from(applicableDesignations),
      'applicable_employment_types': List<String>.from(applicableEmploymentTypes),
      'attachment_required': attachmentRequired,
      'medical_certificate_required': medicalCertificateRequired,
      'medical_certificate_after_days': medicalCertificateAfterDays,
      'sandwich_leave_enabled': sandwichLeaveEnabled,
      'count_holidays_as_leave': countHolidaysAsLeave,
      'count_weekoffs_as_leave': countWeekoffsAsLeave,
      'allow_negative_balance': allowNegativeBalance,
      'convert_to_lop': convertToLop,
      'allow_leave_cancellation': allowLeaveCancellation,
      'cancellation_allowed_until': cancellationAllowedUntil,
      'allow_leave_extension': allowLeaveExtension,
      'allow_leave_combination': allowLeaveCombination,
      'policy_note': policyNote,
    };
  }
}

/// One `SettingsAuditLog` row for a leave type — mirrors the web's
/// `interface AuditEntry`.
class LeaveAuditEntry {
  final int id;
  final String actorName;
  final String action;
  final DateTime? createdAt;

  const LeaveAuditEntry({
    required this.id,
    required this.actorName,
    required this.action,
    required this.createdAt,
  });

  factory LeaveAuditEntry.fromJson(Map<String, dynamic> json) {
    return LeaveAuditEntry(
      id: json['id'] as int,
      actorName: json['actor_name'] as String? ?? '—',
      action: json['action'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
