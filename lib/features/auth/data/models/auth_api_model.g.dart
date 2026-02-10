
part of 'auth_api_model.dart';



AuthApiModel _$AuthApiModelFromJson(Map<String, dynamic> json) => AuthApiModel(
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String,
  password: json['password'] as String,
  phone: json['phone'] as String,
  education: json['education'] as String,
);

Map<String, dynamic> _$AuthApiModelToJson(AuthApiModel instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'password': instance.password,
      'phone': instance.phone,
      'education': instance.education,
    };
