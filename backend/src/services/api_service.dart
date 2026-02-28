import 'package:dio/dio.dart';

// Set at build time: flutter run --dart-define=USE_EMULATOR=true
const bool useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

class ApiService {
  static const _emulatorBase = 'http://10.0.2.2:5050/api';
  static const _deviceBase = 'http://192.168.1.3:5050/api';

  Dio _buildClient(String baseUrl) => Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 35),
        ),
      );

  // Point to the actual backend API (adjust host/port if your server differs).
  late Dio dio = _buildClient(useEmulator ? _emulatorBase : _deviceBase);

  Future<Response> getData(String endpoint) async {
    try {
      return await dio.get(endpoint);
    } on DioException catch (e) {
      final isConnIssue = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError;
      final nextBase =
          dio.options.baseUrl == _deviceBase ? _emulatorBase : _deviceBase;

      if (isConnIssue && dio.options.baseUrl != nextBase) {
        dio = _buildClient(nextBase);
        return dio.get(endpoint);
      }
      rethrow;
    }
  }
}
