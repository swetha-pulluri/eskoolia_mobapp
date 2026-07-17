// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      email: json['email'] as String,
      first_name: json['first_name'] as String? ?? '',
      last_name: json['last_name'] as String? ?? '',
      school_id: (json['school_id'] as num?)?.toInt(),
      school_name: json['school_name'] as String?,
      portal_type: json['portal_type'] as String? ?? 'admin',
      is_superuser: json['is_superuser'] as bool? ?? false,
      is_school_admin: json['is_school_admin'] as bool? ?? false,
      role_ids: (json['role_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      role_names: (json['role_names'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      permission_codes: (json['permission_codes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      must_change_password: json['must_change_password'] as bool? ?? false,
      llm_enabled: json['llm_enabled'] as bool? ?? true,
      class_section: json['class_section'] as String?,
      school_branding: json['school_branding'] == null
          ? null
          : SchoolBrandingModel.fromJson(
              json['school_branding'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'first_name': instance.first_name,
      'last_name': instance.last_name,
      'school_id': instance.school_id,
      'school_name': instance.school_name,
      'portal_type': instance.portal_type,
      'is_superuser': instance.is_superuser,
      'is_school_admin': instance.is_school_admin,
      'role_ids': instance.role_ids,
      'role_names': instance.role_names,
      'permission_codes': instance.permission_codes,
      'must_change_password': instance.must_change_password,
      'llm_enabled': instance.llm_enabled,
      'class_section': instance.class_section,
      'school_branding': instance.school_branding,
    };

_$SchoolBrandingModelImpl _$$SchoolBrandingModelImplFromJson(
        Map<String, dynamic> json) =>
    _$SchoolBrandingModelImpl(
      name: json['name'] as String?,
      brand_color: json['brand_color'] as String?,
      logo_url: json['logo_url'] as String?,
    );

Map<String, dynamic> _$$SchoolBrandingModelImplToJson(
        _$SchoolBrandingModelImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'brand_color': instance.brand_color,
      'logo_url': instance.logo_url,
    };
