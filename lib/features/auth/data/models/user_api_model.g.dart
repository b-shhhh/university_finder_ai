// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_api_model.dart';

UserApiModel _$UserApiModelFromJson(Map<String, dynamic> json) => UserApiModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      country: json['country'] as String?,
      bio: json['bio'] as String?,
      role: json['role']?.toString() ?? 'user',
      profilePic: json['profilePic'] as String?,
      savedUniversities: (json['savedUniversities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );

Map<String, dynamic> _$UserApiModelToJson(UserApiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'phone': instance.phone,
      'country': instance.country,
      'bio': instance.bio,
      'role': instance.role,
      'profilePic': instance.profilePic,
      'savedUniversities': instance.savedUniversities,
    };
