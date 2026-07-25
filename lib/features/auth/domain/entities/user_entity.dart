import 'package:equatable/equatable.dart';

/// User Entity - Domain layer
/// Business object for user data
class UserEntity extends Equatable {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final int? schoolId;
  final String? schoolName;
  final String portalType;
  final bool isSuperuser;
  final List<String> roleNames;
  final bool mustChangePassword;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.schoolId,
    this.schoolName,
    required this.portalType,
    required this.isSuperuser,
    required this.roleNames,
    required this.mustChangePassword,
  });

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    firstName,
    lastName,
    schoolId,
    schoolName,
    portalType,
    isSuperuser,
    roleNames,
    mustChangePassword,
  ];
}
