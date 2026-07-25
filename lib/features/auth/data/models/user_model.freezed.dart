// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  int get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get first_name => throw _privateConstructorUsedError;
  String get last_name => throw _privateConstructorUsedError;
  int? get school_id => throw _privateConstructorUsedError;
  String? get school_name => throw _privateConstructorUsedError;
  String get portal_type => throw _privateConstructorUsedError;
  bool get is_superuser => throw _privateConstructorUsedError;
  bool get is_school_admin => throw _privateConstructorUsedError;
  List<int> get role_ids => throw _privateConstructorUsedError;
  List<String> get role_names => throw _privateConstructorUsedError;
  List<String> get permission_codes => throw _privateConstructorUsedError;
  bool get must_change_password => throw _privateConstructorUsedError;
  bool get llm_enabled => throw _privateConstructorUsedError;
  String? get class_section => throw _privateConstructorUsedError;
  SchoolBrandingModel? get school_branding =>
      throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call({
    int id,
    String username,
    String email,
    String first_name,
    String last_name,
    int? school_id,
    String? school_name,
    String portal_type,
    bool is_superuser,
    bool is_school_admin,
    List<int> role_ids,
    List<String> role_names,
    List<String> permission_codes,
    bool must_change_password,
    bool llm_enabled,
    String? class_section,
    SchoolBrandingModel? school_branding,
  });

  $SchoolBrandingModelCopyWith<$Res>? get school_branding;
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? first_name = null,
    Object? last_name = null,
    Object? school_id = freezed,
    Object? school_name = freezed,
    Object? portal_type = null,
    Object? is_superuser = null,
    Object? is_school_admin = null,
    Object? role_ids = null,
    Object? role_names = null,
    Object? permission_codes = null,
    Object? must_change_password = null,
    Object? llm_enabled = null,
    Object? class_section = freezed,
    Object? school_branding = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            first_name: null == first_name
                ? _value.first_name
                : first_name // ignore: cast_nullable_to_non_nullable
                      as String,
            last_name: null == last_name
                ? _value.last_name
                : last_name // ignore: cast_nullable_to_non_nullable
                      as String,
            school_id: freezed == school_id
                ? _value.school_id
                : school_id // ignore: cast_nullable_to_non_nullable
                      as int?,
            school_name: freezed == school_name
                ? _value.school_name
                : school_name // ignore: cast_nullable_to_non_nullable
                      as String?,
            portal_type: null == portal_type
                ? _value.portal_type
                : portal_type // ignore: cast_nullable_to_non_nullable
                      as String,
            is_superuser: null == is_superuser
                ? _value.is_superuser
                : is_superuser // ignore: cast_nullable_to_non_nullable
                      as bool,
            is_school_admin: null == is_school_admin
                ? _value.is_school_admin
                : is_school_admin // ignore: cast_nullable_to_non_nullable
                      as bool,
            role_ids: null == role_ids
                ? _value.role_ids
                : role_ids // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            role_names: null == role_names
                ? _value.role_names
                : role_names // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            permission_codes: null == permission_codes
                ? _value.permission_codes
                : permission_codes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            must_change_password: null == must_change_password
                ? _value.must_change_password
                : must_change_password // ignore: cast_nullable_to_non_nullable
                      as bool,
            llm_enabled: null == llm_enabled
                ? _value.llm_enabled
                : llm_enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            class_section: freezed == class_section
                ? _value.class_section
                : class_section // ignore: cast_nullable_to_non_nullable
                      as String?,
            school_branding: freezed == school_branding
                ? _value.school_branding
                : school_branding // ignore: cast_nullable_to_non_nullable
                      as SchoolBrandingModel?,
          )
          as $Val,
    );
  }

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SchoolBrandingModelCopyWith<$Res>? get school_branding {
    if (_value.school_branding == null) {
      return null;
    }

    return $SchoolBrandingModelCopyWith<$Res>(_value.school_branding!, (value) {
      return _then(_value.copyWith(school_branding: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
    _$UserModelImpl value,
    $Res Function(_$UserModelImpl) then,
  ) = __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String username,
    String email,
    String first_name,
    String last_name,
    int? school_id,
    String? school_name,
    String portal_type,
    bool is_superuser,
    bool is_school_admin,
    List<int> role_ids,
    List<String> role_names,
    List<String> permission_codes,
    bool must_change_password,
    bool llm_enabled,
    String? class_section,
    SchoolBrandingModel? school_branding,
  });

  @override
  $SchoolBrandingModelCopyWith<$Res>? get school_branding;
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
    _$UserModelImpl _value,
    $Res Function(_$UserModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? first_name = null,
    Object? last_name = null,
    Object? school_id = freezed,
    Object? school_name = freezed,
    Object? portal_type = null,
    Object? is_superuser = null,
    Object? is_school_admin = null,
    Object? role_ids = null,
    Object? role_names = null,
    Object? permission_codes = null,
    Object? must_change_password = null,
    Object? llm_enabled = null,
    Object? class_section = freezed,
    Object? school_branding = freezed,
  }) {
    return _then(
      _$UserModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        first_name: null == first_name
            ? _value.first_name
            : first_name // ignore: cast_nullable_to_non_nullable
                  as String,
        last_name: null == last_name
            ? _value.last_name
            : last_name // ignore: cast_nullable_to_non_nullable
                  as String,
        school_id: freezed == school_id
            ? _value.school_id
            : school_id // ignore: cast_nullable_to_non_nullable
                  as int?,
        school_name: freezed == school_name
            ? _value.school_name
            : school_name // ignore: cast_nullable_to_non_nullable
                  as String?,
        portal_type: null == portal_type
            ? _value.portal_type
            : portal_type // ignore: cast_nullable_to_non_nullable
                  as String,
        is_superuser: null == is_superuser
            ? _value.is_superuser
            : is_superuser // ignore: cast_nullable_to_non_nullable
                  as bool,
        is_school_admin: null == is_school_admin
            ? _value.is_school_admin
            : is_school_admin // ignore: cast_nullable_to_non_nullable
                  as bool,
        role_ids: null == role_ids
            ? _value._role_ids
            : role_ids // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        role_names: null == role_names
            ? _value._role_names
            : role_names // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        permission_codes: null == permission_codes
            ? _value._permission_codes
            : permission_codes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        must_change_password: null == must_change_password
            ? _value.must_change_password
            : must_change_password // ignore: cast_nullable_to_non_nullable
                  as bool,
        llm_enabled: null == llm_enabled
            ? _value.llm_enabled
            : llm_enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        class_section: freezed == class_section
            ? _value.class_section
            : class_section // ignore: cast_nullable_to_non_nullable
                  as String?,
        school_branding: freezed == school_branding
            ? _value.school_branding
            : school_branding // ignore: cast_nullable_to_non_nullable
                  as SchoolBrandingModel?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl({
    required this.id,
    required this.username,
    required this.email,
    this.first_name = '',
    this.last_name = '',
    this.school_id,
    this.school_name,
    this.portal_type = 'admin',
    this.is_superuser = false,
    this.is_school_admin = false,
    final List<int> role_ids = const [],
    final List<String> role_names = const [],
    final List<String> permission_codes = const [],
    this.must_change_password = false,
    this.llm_enabled = true,
    this.class_section,
    this.school_branding,
  }) : _role_ids = role_ids,
       _role_names = role_names,
       _permission_codes = permission_codes;

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  final int id;
  @override
  final String username;
  @override
  final String email;
  @override
  @JsonKey()
  final String first_name;
  @override
  @JsonKey()
  final String last_name;
  @override
  final int? school_id;
  @override
  final String? school_name;
  @override
  @JsonKey()
  final String portal_type;
  @override
  @JsonKey()
  final bool is_superuser;
  @override
  @JsonKey()
  final bool is_school_admin;
  final List<int> _role_ids;
  @override
  @JsonKey()
  List<int> get role_ids {
    if (_role_ids is EqualUnmodifiableListView) return _role_ids;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_role_ids);
  }

  final List<String> _role_names;
  @override
  @JsonKey()
  List<String> get role_names {
    if (_role_names is EqualUnmodifiableListView) return _role_names;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_role_names);
  }

  final List<String> _permission_codes;
  @override
  @JsonKey()
  List<String> get permission_codes {
    if (_permission_codes is EqualUnmodifiableListView)
      return _permission_codes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_permission_codes);
  }

  @override
  @JsonKey()
  final bool must_change_password;
  @override
  @JsonKey()
  final bool llm_enabled;
  @override
  final String? class_section;
  @override
  final SchoolBrandingModel? school_branding;

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, first_name: $first_name, last_name: $last_name, school_id: $school_id, school_name: $school_name, portal_type: $portal_type, is_superuser: $is_superuser, is_school_admin: $is_school_admin, role_ids: $role_ids, role_names: $role_names, permission_codes: $permission_codes, must_change_password: $must_change_password, llm_enabled: $llm_enabled, class_section: $class_section, school_branding: $school_branding)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.first_name, first_name) ||
                other.first_name == first_name) &&
            (identical(other.last_name, last_name) ||
                other.last_name == last_name) &&
            (identical(other.school_id, school_id) ||
                other.school_id == school_id) &&
            (identical(other.school_name, school_name) ||
                other.school_name == school_name) &&
            (identical(other.portal_type, portal_type) ||
                other.portal_type == portal_type) &&
            (identical(other.is_superuser, is_superuser) ||
                other.is_superuser == is_superuser) &&
            (identical(other.is_school_admin, is_school_admin) ||
                other.is_school_admin == is_school_admin) &&
            const DeepCollectionEquality().equals(other._role_ids, _role_ids) &&
            const DeepCollectionEquality().equals(
              other._role_names,
              _role_names,
            ) &&
            const DeepCollectionEquality().equals(
              other._permission_codes,
              _permission_codes,
            ) &&
            (identical(other.must_change_password, must_change_password) ||
                other.must_change_password == must_change_password) &&
            (identical(other.llm_enabled, llm_enabled) ||
                other.llm_enabled == llm_enabled) &&
            (identical(other.class_section, class_section) ||
                other.class_section == class_section) &&
            (identical(other.school_branding, school_branding) ||
                other.school_branding == school_branding));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    username,
    email,
    first_name,
    last_name,
    school_id,
    school_name,
    portal_type,
    is_superuser,
    is_school_admin,
    const DeepCollectionEquality().hash(_role_ids),
    const DeepCollectionEquality().hash(_role_names),
    const DeepCollectionEquality().hash(_permission_codes),
    must_change_password,
    llm_enabled,
    class_section,
    school_branding,
  );

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(this);
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel({
    required final int id,
    required final String username,
    required final String email,
    final String first_name,
    final String last_name,
    final int? school_id,
    final String? school_name,
    final String portal_type,
    final bool is_superuser,
    final bool is_school_admin,
    final List<int> role_ids,
    final List<String> role_names,
    final List<String> permission_codes,
    final bool must_change_password,
    final bool llm_enabled,
    final String? class_section,
    final SchoolBrandingModel? school_branding,
  }) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  int get id;
  @override
  String get username;
  @override
  String get email;
  @override
  String get first_name;
  @override
  String get last_name;
  @override
  int? get school_id;
  @override
  String? get school_name;
  @override
  String get portal_type;
  @override
  bool get is_superuser;
  @override
  bool get is_school_admin;
  @override
  List<int> get role_ids;
  @override
  List<String> get role_names;
  @override
  List<String> get permission_codes;
  @override
  bool get must_change_password;
  @override
  bool get llm_enabled;
  @override
  String? get class_section;
  @override
  SchoolBrandingModel? get school_branding;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SchoolBrandingModel _$SchoolBrandingModelFromJson(Map<String, dynamic> json) {
  return _SchoolBrandingModel.fromJson(json);
}

/// @nodoc
mixin _$SchoolBrandingModel {
  String? get name => throw _privateConstructorUsedError;
  String? get brand_color => throw _privateConstructorUsedError;
  String? get logo_url => throw _privateConstructorUsedError;

  /// Serializes this SchoolBrandingModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SchoolBrandingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SchoolBrandingModelCopyWith<SchoolBrandingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SchoolBrandingModelCopyWith<$Res> {
  factory $SchoolBrandingModelCopyWith(
    SchoolBrandingModel value,
    $Res Function(SchoolBrandingModel) then,
  ) = _$SchoolBrandingModelCopyWithImpl<$Res, SchoolBrandingModel>;
  @useResult
  $Res call({String? name, String? brand_color, String? logo_url});
}

/// @nodoc
class _$SchoolBrandingModelCopyWithImpl<$Res, $Val extends SchoolBrandingModel>
    implements $SchoolBrandingModelCopyWith<$Res> {
  _$SchoolBrandingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SchoolBrandingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? brand_color = freezed,
    Object? logo_url = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            brand_color: freezed == brand_color
                ? _value.brand_color
                : brand_color // ignore: cast_nullable_to_non_nullable
                      as String?,
            logo_url: freezed == logo_url
                ? _value.logo_url
                : logo_url // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SchoolBrandingModelImplCopyWith<$Res>
    implements $SchoolBrandingModelCopyWith<$Res> {
  factory _$$SchoolBrandingModelImplCopyWith(
    _$SchoolBrandingModelImpl value,
    $Res Function(_$SchoolBrandingModelImpl) then,
  ) = __$$SchoolBrandingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? name, String? brand_color, String? logo_url});
}

/// @nodoc
class __$$SchoolBrandingModelImplCopyWithImpl<$Res>
    extends _$SchoolBrandingModelCopyWithImpl<$Res, _$SchoolBrandingModelImpl>
    implements _$$SchoolBrandingModelImplCopyWith<$Res> {
  __$$SchoolBrandingModelImplCopyWithImpl(
    _$SchoolBrandingModelImpl _value,
    $Res Function(_$SchoolBrandingModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SchoolBrandingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? brand_color = freezed,
    Object? logo_url = freezed,
  }) {
    return _then(
      _$SchoolBrandingModelImpl(
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        brand_color: freezed == brand_color
            ? _value.brand_color
            : brand_color // ignore: cast_nullable_to_non_nullable
                  as String?,
        logo_url: freezed == logo_url
            ? _value.logo_url
            : logo_url // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SchoolBrandingModelImpl implements _SchoolBrandingModel {
  const _$SchoolBrandingModelImpl({this.name, this.brand_color, this.logo_url});

  factory _$SchoolBrandingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SchoolBrandingModelImplFromJson(json);

  @override
  final String? name;
  @override
  final String? brand_color;
  @override
  final String? logo_url;

  @override
  String toString() {
    return 'SchoolBrandingModel(name: $name, brand_color: $brand_color, logo_url: $logo_url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SchoolBrandingModelImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.brand_color, brand_color) ||
                other.brand_color == brand_color) &&
            (identical(other.logo_url, logo_url) ||
                other.logo_url == logo_url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, brand_color, logo_url);

  /// Create a copy of SchoolBrandingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SchoolBrandingModelImplCopyWith<_$SchoolBrandingModelImpl> get copyWith =>
      __$$SchoolBrandingModelImplCopyWithImpl<_$SchoolBrandingModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SchoolBrandingModelImplToJson(this);
  }
}

abstract class _SchoolBrandingModel implements SchoolBrandingModel {
  const factory _SchoolBrandingModel({
    final String? name,
    final String? brand_color,
    final String? logo_url,
  }) = _$SchoolBrandingModelImpl;

  factory _SchoolBrandingModel.fromJson(Map<String, dynamic> json) =
      _$SchoolBrandingModelImpl.fromJson;

  @override
  String? get name;
  @override
  String? get brand_color;
  @override
  String? get logo_url;

  /// Create a copy of SchoolBrandingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SchoolBrandingModelImplCopyWith<_$SchoolBrandingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
