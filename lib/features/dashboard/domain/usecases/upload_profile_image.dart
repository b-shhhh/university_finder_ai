import 'dart:io';
import 'package:dio/dio.dart';

class UploadProfileImage {
  final String uploadUrl;

  UploadProfileImage({required this.uploadUrl});

  Future<String> call(File image) async {
    final dio = Dio();
    final form = FormData.fromMap({
      'profilePic': await MultipartFile.fromFile(image.path, filename: image.uri.pathSegments.last),
    });
    final res = await dio.put(uploadUrl, data: form);
    if ((res.statusCode ?? 500) < 300) {
      final data = res.data as Map<String, dynamic>;
      final updated = data['data'] as Map<String, dynamic>?;
      return (updated?['profilePic'] ?? '').toString();
    }
    throw Exception('Failed to upload image');
  }
}
