import 'package:dio/dio.dart';
import 'dart:io' show SocketException;
import '../../models/auth_api_model.dart';
import '../../models/user_api_model.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';

class AuthRemoteDataSource {
  final ApiClient _client = ApiClient.I;

  /// Register user via API
  Future<AuthApiModel> registerUser(Map<String, dynamic> payload) async {
    try {
      final Response res = await _client.post(ApiEndpoints.register, data: payload);
      return AuthApiModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Login user via API
  Future<AuthApiModel> loginUser(String email, String password) async {
    try {
      final Response res = await _client.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });
      return AuthApiModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Fetch authenticated user profile
  Future<UserApiModel> whoAmI() async {
    try {
      final Response res = await _client.get(ApiEndpoints.whoAmI);
      return UserApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    // Try to extract error message from response body first
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    
    // Fallback to Dio error message
    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }
    
    // Fall back to exception type name
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout - unable to reach the server';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Response timeout - server took too long to respond';
    } else if (e.type == DioExceptionType.sendTimeout) {
      return 'Send timeout - could not send request to server';
    } else if (e.type == DioExceptionType.unknown) {
      if (e.error is SocketException) {
        return 'Network error - ${(e.error as SocketException).osError?.message}. Please check if the server is running at ${e.requestOptions.uri}.';
      }
      return 'Network error - please check your internet connection and server URL';
    }
    
    return 'Network error';
  }
}
