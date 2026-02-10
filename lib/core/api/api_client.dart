import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';

class ApiClient {
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse(ApiEndpoints.baseUrl + endpoint);
    return await http.get(url);
  }

  Future<http.Response> post(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    final url = Uri.parse(ApiEndpoints.baseUrl + endpoint);
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }
}
