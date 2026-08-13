/// Static wizard data for Settings → Leave Policy — a straight port of
/// `frontend/components/settings/LeavePolicyPanel.tsx`'s `FIELD_GROUPS`,
/// `EMPLOYMENT_TYPES`, `WIZARD_HELP_STEPS`, `IDENTITY_KEYS`, `ALL_FIELD_KEYS`,
/// `SCOPE_KEYS` and `WIZARD_DEFAULTS`.
library;

import 'package:flutter/material.dart';

enum LeaveFieldType { number, checkbox, select, text }

class LeaveFieldSpec {
  final String key;
  final String label;
  final LeaveFieldType type;

  const LeaveFieldSpec({required this.key, required this.label, required this.type});
}

class LeaveFieldGroup {
  final String title;
  final IconData icon;
  final List<LeaveFieldSpec> fields;

  const LeaveFieldGroup({required this.title, required this.icon, required this.fields});
}

const List<LeaveFieldGroup> leaveFieldGroups = [
  LeaveFieldGroup(
    title: 'Carry-Forward',
    icon: Icons.refresh,
    fields: [
      LeaveFieldSpec(key: 'can_carry_forward', label: 'Allow carry-forward', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'carry_forward_type', label: 'Carry-forward type', type: LeaveFieldType.select),
      LeaveFieldSpec(key: 'carry_forward_mode', label: 'Carry-forward mode', type: LeaveFieldType.select),
      LeaveFieldSpec(key: 'max_carry_forward_days', label: 'Max carry-forward days', type: LeaveFieldType.number),
      LeaveFieldSpec(
        key: 'carry_forward_expiry_days',
        label: 'Carry-forward expiry (days, 0 = never)',
        type: LeaveFieldType.number,
      ),
    ],
  ),
  LeaveFieldGroup(
    title: 'Duration Limits',
    icon: Icons.date_range_outlined,
    fields: [
      LeaveFieldSpec(key: 'minimum_leave_duration', label: 'Min. days per request (0 = none)', type: LeaveFieldType.number),
      LeaveFieldSpec(key: 'maximum_leave_duration', label: 'Max days per request (0 = none)', type: LeaveFieldType.number),
      LeaveFieldSpec(key: 'maximum_consecutive_days', label: 'Max consecutive days (0 = none)', type: LeaveFieldType.number),
      LeaveFieldSpec(key: 'allow_half_day', label: 'Allow half-day', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'allow_backdated_leave', label: 'Allow backdated leave', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'maximum_backdated_days', label: 'Max backdated days', type: LeaveFieldType.number),
      LeaveFieldSpec(key: 'allow_future_leave', label: 'Allow future-dated leave', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'maximum_future_days', label: 'Max days in advance (0 = none)', type: LeaveFieldType.number),
    ],
  ),
  LeaveFieldGroup(
    title: 'Eligibility',
    icon: Icons.people_outline,
    fields: [
      LeaveFieldSpec(key: 'applicable_gender', label: 'Applicable gender', type: LeaveFieldType.select),
      LeaveFieldSpec(key: 'minimum_service_period', label: 'Min. service period (months)', type: LeaveFieldType.number),
      LeaveFieldSpec(key: 'minimum_notice_period', label: 'Min. notice period (days)', type: LeaveFieldType.number),
      LeaveFieldSpec(key: 'allow_probation_leave', label: 'Allow during probation', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'allow_notice_period_leave', label: 'Allow during notice period', type: LeaveFieldType.checkbox),
    ],
  ),
  LeaveFieldGroup(
    title: 'Documentation',
    icon: Icons.description_outlined,
    fields: [
      LeaveFieldSpec(key: 'attachment_required', label: 'Attachment required', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'medical_certificate_required', label: 'Medical certificate required', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'medical_certificate_after_days', label: '...required after this many days', type: LeaveFieldType.number),
    ],
  ),
  LeaveFieldGroup(
    title: 'Holidays & Week-offs',
    icon: Icons.event_busy_outlined,
    fields: [
      LeaveFieldSpec(key: 'sandwich_leave_enabled', label: 'Sandwich leave rule', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'count_holidays_as_leave', label: 'Count holidays as leave', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'count_weekoffs_as_leave', label: 'Count week-offs as leave', type: LeaveFieldType.checkbox),
    ],
  ),
  LeaveFieldGroup(
    title: 'Balance & Cancellation',
    icon: Icons.balance_outlined,
    fields: [
      LeaveFieldSpec(key: 'allow_negative_balance', label: 'Allow negative balance', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'convert_to_lop', label: 'Convert to Loss of Pay when exhausted', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'allow_leave_cancellation', label: 'Allow cancellation', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(
        key: 'cancellation_allowed_until',
        label: '...within this many days of start (0 = anytime)',
        type: LeaveFieldType.number,
      ),
      LeaveFieldSpec(key: 'allow_leave_extension', label: 'Allow extension', type: LeaveFieldType.checkbox),
      LeaveFieldSpec(key: 'allow_leave_combination', label: 'Allow combining with other leave types', type: LeaveFieldType.checkbox),
    ],
  ),
  LeaveFieldGroup(
    title: 'Note',
    icon: Icons.sticky_note_2_outlined,
    fields: [
      LeaveFieldSpec(key: 'policy_note', label: 'Policy note shown to staff', type: LeaveFieldType.text),
    ],
  ),
];

class LeaveEmploymentType {
  final String value;
  final String label;
  const LeaveEmploymentType(this.value, this.label);
}

const List<LeaveEmploymentType> employmentTypeOptions = [
  LeaveEmploymentType('permanent', 'Permanent'),
  LeaveEmploymentType('contract', 'Contract'),
];

/// Hardcoded per-key select option lists (`renderField`'s inline
/// `key === ... ? [...] : [...]`), each rendered Capitalized in the UI.
const Map<String, List<String>> leaveSelectOptions = {
  'carry_forward_type': ['limited', 'unlimited'],
  'carry_forward_mode': ['automatic', 'manual'],
  'applicable_gender': ['all', 'male', 'female'],
};

const List<String> identityKeys = ['name', 'max_days_per_year', 'is_paid', 'is_active'];
const List<String> scopeKeys = ['applicable_departments', 'applicable_designations', 'applicable_employment_types'];
final List<String> allFieldKeys = [
  for (final group in leaveFieldGroups) for (final field in group.fields) field.key,
];

/// Wizard steps, in order — Identity, then one per [leaveFieldGroups] entry,
/// then Review. Mirrors `WIZARD_STEPS`.
final List<({String label, IconData icon})> leaveWizardSteps = [
  (label: 'Identity', icon: Icons.verified_outlined),
  for (final group in leaveFieldGroups) (label: group.title, icon: group.icon),
  (label: 'Review', icon: Icons.fact_check_outlined),
];

/// One-line per-step description shown in the wizard's help dialog —
/// mirrors `WIZARD_HELP_STEPS`.
const List<({String label, String description})> leaveWizardHelpSteps = [
  (label: 'Identity', description: 'Name the leave type, set the days allowed per year, and mark it paid/active.'),
  (
    label: 'Carry-Forward',
    description:
        'Whether unused days roll into next year, any cap, and whether it happens automatically or needs a manual run.',
  ),
  (
    label: 'Duration Limits',
    description: 'Min/max days per request, half-day requests, and how far back or ahead staff can book.',
  ),
  (
    label: 'Eligibility',
    description: 'Who this leave type applies to — gender, minimum service period, notice period, probation.',
  ),
  (
    label: 'Documentation',
    description: 'Whether an attachment or medical certificate is required, and after how many days.',
  ),
  (
    label: 'Holidays & Week-offs',
    description: 'How holidays and weekly offs inside a leave request are counted (sandwich rule, etc.).',
  ),
  (
    label: 'Balance & Cancellation',
    description: 'Negative balances, converting exhausted leave to Loss of Pay, and cancellation/extension rules.',
  ),
  (label: 'Note', description: 'An optional note shown to staff when they apply for this leave type.'),
  (label: 'Review', description: 'Check everything at a glance before saving.'),
];

/// Fresh-draft defaults for "Add Another Leave Type" — mirrors
/// `WIZARD_DEFAULTS`.
Map<String, dynamic> buildLeaveWizardDefaults() => {
      'name': '',
      'max_days_per_year': 10,
      'is_paid': true,
      'is_active': true,
      'can_carry_forward': false,
      'max_carry_forward_days': 0,
      'carry_forward_type': 'limited',
      'carry_forward_expiry_days': 0,
      'carry_forward_mode': 'automatic',
      'minimum_leave_duration': 0,
      'maximum_leave_duration': 0,
      'maximum_consecutive_days': 0,
      'allow_half_day': true,
      'allow_backdated_leave': false,
      'maximum_backdated_days': 0,
      'allow_future_leave': true,
      'maximum_future_days': 0,
      'applicable_gender': 'all',
      'minimum_service_period': 0,
      'minimum_notice_period': 0,
      'allow_probation_leave': false,
      'allow_notice_period_leave': false,
      'attachment_required': false,
      'medical_certificate_required': false,
      'medical_certificate_after_days': 0,
      'sandwich_leave_enabled': false,
      'count_holidays_as_leave': false,
      'count_weekoffs_as_leave': false,
      'allow_negative_balance': false,
      'convert_to_lop': false,
      'allow_leave_cancellation': true,
      'cancellation_allowed_until': 0,
      'allow_leave_extension': false,
      'allow_leave_combination': false,
      'policy_note': '',
      'applicable_departments': <String>[],
      'applicable_designations': <String>[],
      'applicable_employment_types': <String>[],
    };

String capitalize(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
