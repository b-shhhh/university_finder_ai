import 'dart:async';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'api_endpoints.dart';

/// Centralized REST client configured for the backend API.
/// Now supports host fallback so it works on both emulator and physical device without manual switches.
class ApiClient {
  ApiClient._internal() {
    _baseCandidates = _buildBaseCandidates();
    _dio = _newDio(_baseCandidates.first);
  }

  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get I => _instance;

  late Dio _dio;
  late List<String> _baseCandidates;
  static const _tokenKey = 'auth_token';
  static const _tokenStorage = FlutterSecureStorage();

  Dio _newDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // Balanced: tolerant of cold starts without 25s noise.
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
      ),
    );

    // Auth token injector
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) async {
        final token = await _tokenStorage.read(key: _tokenKey);
        if (token != null && token.isNotEmpty && !_isLocalOfflineToken(token)) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      }, onError: (error, handler) async {
        // Auto-clear token on 401 to prevent stale sessions
        final authHeader = error.requestOptions.headers['Authorization']?.toString() ?? '';
        if (error.response?.statusCode == 401 && authHeader.startsWith('Bearer ')) {
          await clearToken();
        }
        return handler.next(error);
      }),
    );

    // Retry idempotent GET/HEAD
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        logPrint: (obj) {},
        retries: 1,
        retryDelays: const [Duration(milliseconds: 300)],
        retryEvaluator: (error, attempt) {
          final method = error.requestOptions.method.toUpperCase();
          final isIdempotent = method == 'GET' || method == 'HEAD';
          return isIdempotent && attempt < 2;
        },
      ),
    );

    // Logging (dev only)
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          // Disable response body logging to avoid blowing memory on large payloads (e.g., universities list)
          responseBody: false,
          responseHeader: false,
          compact: true,
        ),
      );
    }

    return dio;
  }

  static List<String> _buildBaseCandidates() {
    const base = ApiEndpoints.baseUrl;
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');

    final candidates = <String>[];
    void addIfMissing(String v) {
      if (v.isNotEmpty && !candidates.contains(v)) candidates.add(v);
    }

    if (!kIsWeb && Platform.isAndroid) {
      // Prefer only the explicitly configured host. Map localhost-style
      // hosts to emulator loopback when needed, but do not silently inject
      // 10.0.2.2 for every Android run.
      if (override.isNotEmpty) addIfMissing(override);
      addIfMissing(base);
      if ((override.isNotEmpty &&
              (override.contains('localhost') || override.contains('127.0.0.1'))) ||
          base.contains('localhost') ||
          base.contains('127.0.0.1')) {
        addIfMissing(
          (override.isNotEmpty ? override : base).replaceFirst(
            RegExp(r'localhost|127\\.0\\.0\\.1'),
            '10.0.2.2',
          ),
        );
      }
    } else {
      if (override.isNotEmpty) addIfMissing(override);
      addIfMissing(base);
    }
    return candidates;
  }

  Future<Response<T>> _withFallback<T>(
    String path,
    Future<Response<T>> Function(Dio client) run,
  ) async {
    DioException? lastConnErr;

    for (final base in _baseCandidates) {
      if (_dio.options.baseUrl != base) {
        _dio = _newDio(base);
      }
      try {
        return await run(_dio);
      } on DioException catch (e) {
        final isConnIssue = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError;
        if (!isConnIssue) rethrow; // surface server / auth errors
        lastConnErr = e;
        // try next host
      }
    }

    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 504,
      data: {
        'message': 'Unable to reach server right now.',
        'error': lastConnErr?.message ?? 'All hosts unreachable',
      } as T?,
    );
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) async {
    return _withFallback<T>(path, (c) => c.get<T>(path, queryParameters: query));
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    return _withFallback<T>(path, (c) => c.post<T>(path, data: data));
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) async {
    return _withFallback<T>(path, (c) => c.put<T>(path, data: data));
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) async {
    return _withFallback<T>(path, (c) => c.delete<T>(path, data: data));
  }

  /// Persist JWT for subsequent requests.
  Future<void> saveToken(String token) => _tokenStorage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _tokenStorage.delete(key: _tokenKey);

  bool _isLocalOfflineToken(String token) => token.startsWith('local-');
}
