// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LoginResponseModelImpl _$$LoginResponseModelImplFromJson(
        Map<String, dynamic> json) =>
    _$LoginResponseModelImpl(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      must_change_password: json['must_change_password'] as bool? ?? false,
      school_code: json['school_code'] as String?,
      tenant_id: json['tenant_id'] as String?,
      is_super_admin: json['is_super_admin'] as bool? ?? false,
      portal_type: json['portal_type'] as String? ?? 'admin',
    );

Map<String, dynamic> _$$LoginResponseModelImplToJson(
        _$LoginResponseModelImpl instance) =>
    <String, dynamic>{
      'access': instance.access,
      'refresh': instance.refresh,
      'must_change_password': instance.must_change_password,
      'school_code': instance.school_code,
      'tenant_id': instance.tenant_id,
      'is_super_admin': instance.is_super_admin,
      'portal_type': instance.portal_type,
    };
