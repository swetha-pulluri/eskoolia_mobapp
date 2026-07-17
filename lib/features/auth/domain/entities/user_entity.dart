import 'package:equatable/equatable.dart';

/// User Entity
class UserEntity extends Equatable {
  final String? id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? email;

  const UserEntity({
    this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    return username ?? '';
  }

  @override
  List<Object?> get props => [id, username, firstName, lastName, email];
}
