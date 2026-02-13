import 'package:dio/dio.dart';
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
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    return e.message ?? 'Network error';
  }
}
