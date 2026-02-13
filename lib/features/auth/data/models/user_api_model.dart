import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/auth_entity.dart';

part 'user_api_model.g.dart';

@JsonSerializable()
class UserApiModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? country;
  final String? bio;
  final String role;
  final String? profilePic;
  final List<String> savedUniversities;

  UserApiModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.country,
    this.bio,
    this.role = 'user',
    this.profilePic,
    this.savedUniversities = const [],
  });

  factory UserApiModel.fromJson(Map<String, dynamic> json) => _$UserApiModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserApiModelToJson(this);

  AuthEntity toEntity() => AuthEntity(
        id: id,
        fullName: fullName,
        email: email,
        phone: phone,
        country: country,
        bio: bio,
        role: role,
        profilePic: profilePic,
        savedUniversities: savedUniversities,
      );
}
