import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_response_model.freezed.dart';
part 'login_response_model.g.dart';

/// Login Response Model
/// Reference: backend/apps/users/serializers.py - LoginTokenObtainPairSerializer response
@freezed
class LoginResponseModel with _$LoginResponseModel {
  const factory LoginResponseModel({
    required String access,
    required String refresh,
    @Default(false) bool must_change_password,
    String? school_code,
    String? tenant_id,
    @Default(false) bool is_super_admin,
    @Default('admin') String portal_type, // admin, teacher, parent, student
  }) = _LoginResponseModel;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseModelFromJson(json);
}
