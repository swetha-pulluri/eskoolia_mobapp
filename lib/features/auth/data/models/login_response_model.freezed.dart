// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LoginResponseModel _$LoginResponseModelFromJson(Map<String, dynamic> json) {
  return _LoginResponseModel.fromJson(json);
}

/// @nodoc
mixin _$LoginResponseModel {
  String get access => throw _privateConstructorUsedError;
  String get refresh => throw _privateConstructorUsedError;
  bool get must_change_password => throw _privateConstructorUsedError;
  String? get school_code => throw _privateConstructorUsedError;
  String? get tenant_id => throw _privateConstructorUsedError;
  bool get is_super_admin => throw _privateConstructorUsedError;
  String get portal_type => throw _privateConstructorUsedError;

  /// Serializes this LoginResponseModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoginResponseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoginResponseModelCopyWith<LoginResponseModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginResponseModelCopyWith<$Res> {
  factory $LoginResponseModelCopyWith(
    LoginResponseModel value,
    $Res Function(LoginResponseModel) then,
  ) = _$LoginResponseModelCopyWithImpl<$Res, LoginResponseModel>;
  @useResult
  $Res call({
    String access,
    String refresh,
    bool must_change_password,
    String? school_code,
    String? tenant_id,
    bool is_super_admin,
    String portal_type,
  });
}

/// @nodoc
class _$LoginResponseModelCopyWithImpl<$Res, $Val extends LoginResponseModel>
    implements $LoginResponseModelCopyWith<$Res> {
  _$LoginResponseModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginResponseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? access = null,
    Object? refresh = null,
    Object? must_change_password = null,
    Object? school_code = freezed,
    Object? tenant_id = freezed,
    Object? is_super_admin = null,
    Object? portal_type = null,
  }) {
    return _then(
      _value.copyWith(
            access: null == access
                ? _value.access
                : access // ignore: cast_nullable_to_non_nullable
                      as String,
            refresh: null == refresh
                ? _value.refresh
                : refresh // ignore: cast_nullable_to_non_nullable
                      as String,
            must_change_password: null == must_change_password
                ? _value.must_change_password
                : must_change_password // ignore: cast_nullable_to_non_nullable
                      as bool,
            school_code: freezed == school_code
                ? _value.school_code
                : school_code // ignore: cast_nullable_to_non_nullable
                      as String?,
            tenant_id: freezed == tenant_id
                ? _value.tenant_id
                : tenant_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            is_super_admin: null == is_super_admin
                ? _value.is_super_admin
                : is_super_admin // ignore: cast_nullable_to_non_nullable
                      as bool,
            portal_type: null == portal_type
                ? _value.portal_type
                : portal_type // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LoginResponseModelImplCopyWith<$Res>
    implements $LoginResponseModelCopyWith<$Res> {
  factory _$$LoginResponseModelImplCopyWith(
    _$LoginResponseModelImpl value,
    $Res Function(_$LoginResponseModelImpl) then,
  ) = __$$LoginResponseModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String access,
    String refresh,
    bool must_change_password,
    String? school_code,
    String? tenant_id,
    bool is_super_admin,
    String portal_type,
  });
}

/// @nodoc
class __$$LoginResponseModelImplCopyWithImpl<$Res>
    extends _$LoginResponseModelCopyWithImpl<$Res, _$LoginResponseModelImpl>
    implements _$$LoginResponseModelImplCopyWith<$Res> {
  __$$LoginResponseModelImplCopyWithImpl(
    _$LoginResponseModelImpl _value,
    $Res Function(_$LoginResponseModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LoginResponseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? access = null,
    Object? refresh = null,
    Object? must_change_password = null,
    Object? school_code = freezed,
    Object? tenant_id = freezed,
    Object? is_super_admin = null,
    Object? portal_type = null,
  }) {
    return _then(
      _$LoginResponseModelImpl(
        access: null == access
            ? _value.access
            : access // ignore: cast_nullable_to_non_nullable
                  as String,
        refresh: null == refresh
            ? _value.refresh
            : refresh // ignore: cast_nullable_to_non_nullable
                  as String,
        must_change_password: null == must_change_password
            ? _value.must_change_password
            : must_change_password // ignore: cast_nullable_to_non_nullable
                  as bool,
        school_code: freezed == school_code
            ? _value.school_code
            : school_code // ignore: cast_nullable_to_non_nullable
                  as String?,
        tenant_id: freezed == tenant_id
            ? _value.tenant_id
            : tenant_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        is_super_admin: null == is_super_admin
            ? _value.is_super_admin
            : is_super_admin // ignore: cast_nullable_to_non_nullable
                  as bool,
        portal_type: null == portal_type
            ? _value.portal_type
            : portal_type // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LoginResponseModelImpl implements _LoginResponseModel {
  const _$LoginResponseModelImpl({
    required this.access,
    required this.refresh,
    this.must_change_password = false,
    this.school_code,
    this.tenant_id,
    this.is_super_admin = false,
    this.portal_type = 'admin',
  });

  factory _$LoginResponseModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoginResponseModelImplFromJson(json);

  @override
  final String access;
  @override
  final String refresh;
  @override
  @JsonKey()
  final bool must_change_password;
  @override
  final String? school_code;
  @override
  final String? tenant_id;
  @override
  @JsonKey()
  final bool is_super_admin;
  @override
  @JsonKey()
  final String portal_type;

  @override
  String toString() {
    return 'LoginResponseModel(access: $access, refresh: $refresh, must_change_password: $must_change_password, school_code: $school_code, tenant_id: $tenant_id, is_super_admin: $is_super_admin, portal_type: $portal_type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginResponseModelImpl &&
            (identical(other.access, access) || other.access == access) &&
            (identical(other.refresh, refresh) || other.refresh == refresh) &&
            (identical(other.must_change_password, must_change_password) ||
                other.must_change_password == must_change_password) &&
            (identical(other.school_code, school_code) ||
                other.school_code == school_code) &&
            (identical(other.tenant_id, tenant_id) ||
                other.tenant_id == tenant_id) &&
            (identical(other.is_super_admin, is_super_admin) ||
                other.is_super_admin == is_super_admin) &&
            (identical(other.portal_type, portal_type) ||
                other.portal_type == portal_type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    access,
    refresh,
    must_change_password,
    school_code,
    tenant_id,
    is_super_admin,
    portal_type,
  );

  /// Create a copy of LoginResponseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginResponseModelImplCopyWith<_$LoginResponseModelImpl> get copyWith =>
      __$$LoginResponseModelImplCopyWithImpl<_$LoginResponseModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LoginResponseModelImplToJson(this);
  }
}

abstract class _LoginResponseModel implements LoginResponseModel {
  const factory _LoginResponseModel({
    required final String access,
    required final String refresh,
    final bool must_change_password,
    final String? school_code,
    final String? tenant_id,
    final bool is_super_admin,
    final String portal_type,
  }) = _$LoginResponseModelImpl;

  factory _LoginResponseModel.fromJson(Map<String, dynamic> json) =
      _$LoginResponseModelImpl.fromJson;

  @override
  String get access;
  @override
  String get refresh;
  @override
  bool get must_change_password;
  @override
  String? get school_code;
  @override
  String? get tenant_id;
  @override
  bool get is_super_admin;
  @override
  String get portal_type;

  /// Create a copy of LoginResponseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginResponseModelImplCopyWith<_$LoginResponseModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
