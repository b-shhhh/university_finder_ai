import 'package:dio/dio.dart';

// Set at build time: flutter run --dart-define=USE_EMULATOR=true
const bool useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

class ApiService {
  static const _emulatorBase = 'http://10.0.2.2:5050/api';
  static const _deviceBase = 'http://192.168.1.3:5050/api';

  // Next.js frontend API (chatbot lives here).
  static const _webEmulatorBase = 'http://10.0.2.2:3000/api';
  static const _webDeviceBase = 'http://192.168.1.3:3000/api';

  Dio _buildClient(String baseUrl) => Dio(
        BaseOptions(
          baseUrl: baseUrl,
          // Slightly higher to tolerate cold-started Next.js dev server.
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

  // Point to the actual backend API (adjust host/port if your server differs).
  late Dio dio = _buildClient(useEmulator ? _emulatorBase : _deviceBase);

  // Separate client for the Next.js frontend API.
  late Dio webDio = _buildClient(useEmulator ? _webEmulatorBase : _webDeviceBase);

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

  Future<Response> postChatbot(String message) async {
    try {
      return await webDio.post('/chatbot', data: {'message': message});
    } on DioException catch (e) {
      final isConnIssue = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError;
      final nextBase =
          webDio.options.baseUrl == _webDeviceBase ? _webEmulatorBase : _webDeviceBase;

      if (isConnIssue && webDio.options.baseUrl != nextBase) {
        webDio = _buildClient(nextBase);
        return webDio.post('/chatbot', data: {'message': message});
      }
      rethrow;
    }
  }
}
