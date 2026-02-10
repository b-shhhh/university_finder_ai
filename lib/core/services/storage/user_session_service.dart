import 'dart:convert';
import 'package:Uniguide/core/services/storage/storage_service.dart';

class UserSessionService {
  final StorageService storage;

  UserSessionService(this.storage);

  /// TOKEN
  Future<void> saveToken(String token) async {
    await storage.saveString('token', token);
  }

  Future<String?> getToken() async {
    return await storage.getString('token');
  }

  /// USER DATA (from login)
  Future<void> saveUser({
    required String userId,
    required String name,
    required String email,
    String? profileImageUrl,
  }) async {
    final userData = {
      'userId': userId,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
    };

    await storage.saveString('user', jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final data = await storage.getString('user');
    if (data == null) return null;
    return jsonDecode(data);
  }

  /// LOGIN STATE
  Future<bool> isLoggedIn() async {
    final token = await storage.getString('token');
    return token != null;
  }

  /// LOGOUT
  Future<void> logout() async {
    await storage.clear();
  }
}
