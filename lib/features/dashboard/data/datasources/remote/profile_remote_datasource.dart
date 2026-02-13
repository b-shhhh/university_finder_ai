import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';

class ProfileRemoteDataSource {
  final ApiClient _client = ApiClient.I;

  Future<Map<String, dynamic>> fetchProfile() async {
    final Response res = await _client.get(ApiEndpoints.userProfile);
    if (res.statusCode == 200) {
      final data = res.data as Map<String, dynamic>;
      return (data['data'] as Map<String, dynamic>?) ?? data;
    }
    throw Exception("Failed to fetch profile");
  }

  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> fields,
    MultipartFile? avatar,
  }) async {
    final form = FormData.fromMap({
      ...fields,
      if (avatar != null) 'profilePic': avatar,
    });
    final Response res = await _client.put(ApiEndpoints.updateProfile, data: form);
    if ((res.statusCode ?? 400) < 300) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception("Failed to update profile");
  }

  Future<Map<String, dynamic>> uploadProfileImage(File file) async {
    final avatar = await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last);
    return updateProfile(fields: {}, avatar: avatar);
  }
}
