import 'package:dio/dio.dart';

// Set at build time: flutter run --dart-define=USE_EMULATOR=true
const bool useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

class ApiService {
  static const _emulatorBase = 'http://10.0.2.2:5050/api';
  // Allow overriding the device/LAN host via --dart-define=API_HOST=192.168.x.x:5050
  static final _deviceBase = () {
    const hostOverride = String.fromEnvironment('API_HOST');
    final host = hostOverride.isNotEmpty ? hostOverride : '192.168.1.3:5050';
    return 'http://$host/api';
  }();
  // Extra candidate based on observed LAN IPs (matches Next.js "Network" host but port 5050).
  static const _deviceAltBase = 'http://192.168.1.6:5050/api';

  // Next.js frontend API (chatbot lives here).
  static const _webEmulatorBase = 'http://10.0.2.2:3000/api';
  // Allow overriding the device/LAN host via --dart-define=WEB_HOST=192.168.x.x:3000
  static final _webDeviceBase = () {
    const hostOverride = String.fromEnvironment('WEB_HOST');
    final host = hostOverride.isNotEmpty ? hostOverride : '192.168.1.3:3000';
    return 'http://$host/api';
  }();
  // Extra candidate based on the latest Next.js "Network" URL shown in logs.
  static const _webAltDeviceBase = 'http://192.168.1.6:3000/api';

  Dio _buildClient(String baseUrl) => Dio(
        BaseOptions(
          baseUrl: baseUrl,
          // Balanced: avoid 25s noise but still tolerant of cold starts.
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );

  // Point to the actual backend API (adjust host/port if your server differs).
  late Dio dio = _buildClient(useEmulator ? _emulatorBase : _deviceBase);

  // Separate client for the Next.js frontend API.
  late Dio webDio = _buildClient(useEmulator ? _webEmulatorBase : _webDeviceBase);

  Future<Response> getData(String endpoint) async {
    final candidates = <String>{
      _deviceBase,
      _deviceAltBase,
      _emulatorBase,
    }.toList();

    DioException? lastConnErr;
    for (final base in candidates) {
      try {
        if (dio.options.baseUrl != base) dio = _buildClient(base);
        return await dio.get(endpoint);
      } on DioException catch (e) {
        final isConnIssue = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError;
        if (!isConnIssue) rethrow;
        lastConnErr = e;
        // try next host
      }
    }

    return Response(
      requestOptions: RequestOptions(path: endpoint),
      statusCode: 504,
      data: {
        'message': 'Unable to reach server right now.',
        'error': lastConnErr?.message ?? 'All backend hosts unreachable',
      },
    );
  }

  Future<Response> postChatbot(String message) async {
    // Try a small set of hosts in order until one responds.
    final candidates = <String>{
      _webDeviceBase, // default or overridden device host
      if (!useEmulator) _webAltDeviceBase, // observed Next.js network host
      _webEmulatorBase, // emulator/host loopback
    }.toList();

    DioException? lastConnErr;
    for (final base in candidates) {
      try {
        if (webDio.options.baseUrl != base) {
          webDio = _buildClient(base);
        }
        return await webDio.post('/chatbot', data: {'message': message});
      } on DioException catch (e) {
        final isConnIssue = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError;
        if (!isConnIssue) rethrow; // surface non-network errors
        lastConnErr = e;
        // try next host
      }
    }

    // Swallow connection errors and return a safe placeholder response
    return Response(
      requestOptions: RequestOptions(path: '/chatbot'),
      statusCode: 504,
      data: {
        'reply': 'Unable to reach chatbot right now. Please check your connection and try again.',
        'universities': [],
        'error': lastConnErr?.message ?? 'All chatbot hosts unreachable',
      },
    );
  }
}
