
part of 'auth_api_model.dart';



AuthApiModel _$AuthApiModelFromJson(Map<String, dynamic> json) => AuthApiModel(
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  password: json['password'] as String,
  phone: json['phone'] as String,
  education: json['education'] as String,
);

Map<String, dynamic> _$AuthApiModelToJson(AuthApiModel instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'email': instance.email,
      'password': instance.password,
      'phone': instance.phone,
      'education': instance.education,
    };
