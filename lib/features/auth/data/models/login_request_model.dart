import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_request_model.freezed.dart';
part 'login_request_model.g.dart';

/// Login Request Model
/// Reference: backend/apps/users/serializers.py - LoginTokenObtainPairSerializer
/// Accepts username, email, phone, or full name + password
@freezed
class LoginRequestModel with _$LoginRequestModel {
  const factory LoginRequestModel({
    required String username, // Can be username, email, phone, or "First Last"
    required String password,
  }) = _LoginRequestModel;

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestModelFromJson(json);
}
