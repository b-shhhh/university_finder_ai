import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/auth_entity.dart';

part 'auth_api_model.g.dart';

@JsonSerializable()
class AuthApiModel {
  final bool success;
  final String token;
  @JsonKey(name: 'data')
  final Map<String, dynamic>? data;

  AuthApiModel({
    required this.success,
    required this.token,
    required this.data,
  });

  /// From JSON
  factory AuthApiModel.fromJson(Map<String, dynamic> json) => _$AuthApiModelFromJson(json);

  /// To JSON (used when registering)
  Map<String, dynamic> toJson() => _$AuthApiModelToJson(this);

  /// Extract user entity from nested data
  AuthEntity toEntity() {
    final userJson = (data ?? const {})['user'] as Map<String, dynamic>? ?? {};
    return AuthEntity(
      id: userJson['id']?.toString() ?? '',
      fullName: userJson['fullName']?.toString() ?? '',
      email: userJson['email']?.toString() ?? '',
      phone: userJson['phone']?.toString() ?? '',
      country: userJson['country']?.toString(),
      bio: userJson['bio']?.toString(),
      role: userJson['role']?.toString() ?? 'user',
      profilePic: userJson['profilePic']?.toString(),
      token: token,
      savedUniversities: (userJson['savedUniversities'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
