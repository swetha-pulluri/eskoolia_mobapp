import 'package:equatable/equatable.dart';

/// Login Entity - Domain layer
/// Business object for login response
class LoginEntity extends Equatable {
  final String accessToken;
  final String refreshToken;
  final bool mustChangePassword;
  final String portalType;
  final String? schoolCode;

  const LoginEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.mustChangePassword,
    required this.portalType,
    this.schoolCode,
  });

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    mustChangePassword,
    portalType,
    schoolCode,
  ];
}
