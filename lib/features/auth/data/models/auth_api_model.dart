import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/auth_entity.dart';

part 'auth_api_model.g.dart';

@JsonSerializable()
class AuthApiModel {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phone;
  final String education;

  AuthApiModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phone,
    required this.education,
  });

  // From JSON
  factory AuthApiModel.fromJson(Map<String, dynamic> json) =>
      _$AuthApiModelFromJson(json);

  // To JSON
  Map<String, dynamic> toJson() => _$AuthApiModelToJson(this);

  // Convert to domain entity
  AuthEntity toEntity() {
    return AuthEntity(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      phone: phone,
      education: education,
    );
  }
}
