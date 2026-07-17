import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  final String? id;
  final String? username;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? email;

  UserDto({
    this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      username: username,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
  }
}
