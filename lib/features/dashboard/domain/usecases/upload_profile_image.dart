import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadProfileImage {
  final String uploadUrl;

  UploadProfileImage({required this.uploadUrl});

  Future<String> call(File image) async {
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.files.add(await http.MultipartFile.fromPath('profilePicture', image.path));
    final response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final jsonData = jsonDecode(body);
      return jsonData['imageUrl']; // return uploaded URL
    } else {
      throw Exception('Failed to upload image');
    }
  }
}
