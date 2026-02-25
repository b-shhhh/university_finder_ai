import 'package:dio/dio.dart';

class ApiService {
  // Point to the actual backend API (adjust host/port if your server differs).
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.6:5050/api',
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 35),
    ),
  );

  Future<Response> getData(String endpoint) async {
    try {
      final response = await dio.get(endpoint);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
