// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'policy_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolicyDto _$PolicyDtoFromJson(Map<String, dynamic> json) => PolicyDto(
  id: json['id'] as String,
  key: json['key'] as String,
  category: json['category'] as String,
  description: json['description'] as String,
  value: json['value'],
  valueType: json['value_type'] as String,
  isToggle: json['is_toggle'] as bool,
  isOverridable: json['is_overridable'] as bool,
  defaultValue: json['default_value'],
);

Map<String, dynamic> _$PolicyDtoToJson(PolicyDto instance) => <String, dynamic>{
  'id': instance.id,
  'key': instance.key,
  'category': instance.category,
  'description': instance.description,
  'value': instance.value,
  'value_type': instance.valueType,
  'is_toggle': instance.isToggle,
  'is_overridable': instance.isOverridable,
  'default_value': instance.defaultValue,
};

PolicyGroupDto _$PolicyGroupDtoFromJson(Map<String, dynamic> json) =>
    PolicyGroupDto(
      category: json['category'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      policies: (json['policies'] as List<dynamic>)
          .map((e) => PolicyDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PolicyGroupDtoToJson(PolicyGroupDto instance) =>
    <String, dynamic>{
      'category': instance.category,
      'label': instance.label,
      'description': instance.description,
      'policies': instance.policies,
    };
