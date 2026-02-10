import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileRemoteDataSource {
  final String baseUrl;

  ProfileRemoteDataSource(this.baseUrl);

  // ✅ ADD THIS METHOD
  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: {
        "Content-Type": "application/json",
        // add Authorization header later if needed
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to fetch profile");
    }
  }

  // existing method (example)
  Future<String> uploadProfileImage(file) async {
    // your upload logic here
    throw UnimplementedError();
  }
}
