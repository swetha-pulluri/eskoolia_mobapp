/// Policy Entity
class PolicyEntity {
  final String key;
  final String label;
  final String description;
  final String type; // 'boolean', 'number', 'string', 'enum'
  final dynamic value;
  final String? unit;
  final List<String>? options;
  final bool isToggle;
  final bool isOverridable;

  const PolicyEntity({
    required this.key,
    required this.label,
    required this.description,
    required this.type,
    required this.value,
    this.unit,
    this.options,
    this.isToggle = false,
    this.isOverridable = true,
  });
}

class PolicyGroupEntity {
  final String group;
  final String displayName;
  final String description;
  final List<PolicyEntity> policies;

  const PolicyGroupEntity({
    required this.group,
    required this.displayName,
    required this.description,
    required this.policies,
  });
}

/// Policies State Entity for UI
class PoliciesStateEntity {
  final List<PolicyEntity> security;
  final List<PolicyEntity> dataIsolation;
  final List<PolicyEntity> billing;
  final List<PolicyEntity> system;

  const PoliciesStateEntity({
    required this.security,
    required this.dataIsolation,
    required this.billing,
    required this.system,
  });
}
