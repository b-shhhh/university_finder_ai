import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/auth_api_model.dart';

class AuthRemoteDataSource {
  final String baseUrl;

  AuthRemoteDataSource({required this.baseUrl});

  /// Register user via API
  Future<AuthApiModel> registerUser(AuthApiModel user) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthApiModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to register user: ${response.statusCode} ${response.body}');
    }
  }

  /// Login user via API
  Future<AuthApiModel> loginUser(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return AuthApiModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to login: ${response.statusCode} ${response.body}');
    }
  }
}
