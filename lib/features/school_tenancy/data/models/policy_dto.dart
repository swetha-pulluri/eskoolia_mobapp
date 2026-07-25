import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/policy_entity.dart';

part 'policy_dto.g.dart';

@JsonSerializable()
class PolicyDto {
  final String id;
  final String key;
  final String category;
  final String description;
  final dynamic value;

  @JsonKey(name: 'value_type')
  final String valueType;

  @JsonKey(name: 'is_toggle')
  final bool isToggle;

  @JsonKey(name: 'is_overridable')
  final bool isOverridable;

  @JsonKey(name: 'default_value')
  final dynamic defaultValue;

  PolicyDto({
    required this.id,
    required this.key,
    required this.category,
    required this.description,
    required this.value,
    required this.valueType,
    required this.isToggle,
    required this.isOverridable,
    this.defaultValue,
  });

  factory PolicyDto.fromJson(Map<String, dynamic> json) => _$PolicyDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PolicyDtoToJson(this);

  /// [key] doubles as the display label — the backend has no separate
  /// "label" field, and the Policies screen renders `policy.key` directly.
  PolicyEntity toEntity() {
    return PolicyEntity(
      key: key,
      label: key,
      description: description,
      type: valueType,
      value: value,
      isToggle: isToggle,
      isOverridable: isOverridable,
      defaultValue: defaultValue,
    );
  }
}

@JsonSerializable()
class PolicyGroupDto {
  final String category;
  final String label;
  final String description;
  final List<PolicyDto> policies;

  PolicyGroupDto({
    required this.category,
    required this.label,
    required this.description,
    required this.policies,
  });

  factory PolicyGroupDto.fromJson(Map<String, dynamic> json) => _$PolicyGroupDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PolicyGroupDtoToJson(this);

  PolicyGroupEntity toEntity() {
    return PolicyGroupEntity(
      group: category,
      displayName: label,
      description: description,
      policies: policies.map((e) => e.toEntity()).toList(),
    );
  }
}
