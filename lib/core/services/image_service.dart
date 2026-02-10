import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageService {
  static const String uploadUrl = 'https://example.com/upload';

  /// Upload image and return image URL from server
  Future<String> uploadImage(File image) async {
    final request =
    http.MultipartRequest('POST', Uri.parse(uploadUrl));

    request.files.add(
      await http.MultipartFile.fromPath('image', image.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['imageUrl']; // server returns image URL
    } else {
      throw Exception('Image upload failed');
    }
  }
}
