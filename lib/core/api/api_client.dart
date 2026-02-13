import 'dart:async';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'api_endpoints.dart';

/// Centralized REST client configured for the backend API.
/// Handles auth header injection, retries for idempotent GETs, and simple error mapping.
class ApiClient {
  ApiClient._internal()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _resolveBaseUrl(),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            responseType: ResponseType.json,
          ),
        ) {
    // Auth token injector
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) async {
        final token = await _tokenStorage.read(key: _tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      }, onError: (error, handler) async {
        // Auto-clear token on 401 to prevent stale sessions
        if (error.response?.statusCode == 401) {
          await clearToken();
        }
        return handler.next(error);
      }),
    );

    // Retry idempotent GET/HEAD
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: (obj) {},
        retries: 2,
        retryDelays: const [
          Duration(milliseconds: 400),
          Duration(seconds: 1),
        ],
        retryEvaluator: (error, attempt) {
          final method = error.requestOptions.method.toUpperCase();
          final isIdempotent = method == 'GET' || method == 'HEAD';
          return isIdempotent && attempt < 2;
        },
      ),
    );

    // Logging (dev only)
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: true,
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get I => _instance;

  final Dio _dio;
  static const _tokenKey = 'auth_token';
  static const _tokenStorage = FlutterSecureStorage();

  static String _resolveBaseUrl() {
    final base = ApiEndpoints.baseUrl;
    if (kIsWeb) return base;
    // Android emulator can't hit localhost; map to host machine.
    if (Platform.isAndroid && base.contains('localhost')) {
      return base.replaceFirst('localhost', '10.0.2.2');
    }
    return base;
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) async {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) async {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) async {
    return _dio.delete<T>(path, data: data);
  }

  /// Persist JWT for subsequent requests.
  Future<void> saveToken(String token) => _tokenStorage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _tokenStorage.delete(key: _tokenKey);
}
