import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User Model
/// Reference: backend/apps/users/views.py - MeView response
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    required String username,
    required String email,
    @Default('') String first_name,
    @Default('') String last_name,
    int? school_id,
    String? school_name,
    @Default('admin') String portal_type,
    @Default(false) bool is_superuser,
    @Default(false) bool is_school_admin,
    @Default([]) List<int> role_ids,
    @Default([]) List<String> role_names,
    @Default([]) List<String> permission_codes,
    @Default(false) bool must_change_password,
    @Default(true) bool llm_enabled,
    String? class_section,
    SchoolBrandingModel? school_branding,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

@freezed
class SchoolBrandingModel with _$SchoolBrandingModel {
  const factory SchoolBrandingModel({
    String? name,
    String? brand_color,
    String? logo_url,
  }) = _SchoolBrandingModel;

  factory SchoolBrandingModel.fromJson(Map<String, dynamic> json) =>
      _$SchoolBrandingModelFromJson(json);
}
