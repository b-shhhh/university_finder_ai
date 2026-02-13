
part of 'auth_api_model.dart';



AuthApiModel _$AuthApiModelFromJson(Map<String, dynamic> json) => AuthApiModel(
      success: json['success'] as bool? ?? false,
      token: json['token'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AuthApiModelToJson(AuthApiModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'token': instance.token,
      'data': instance.data,
    };
