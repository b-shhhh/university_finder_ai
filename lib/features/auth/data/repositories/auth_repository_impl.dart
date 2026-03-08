import 'dart:convert';
import '../../domain/entities/auth_entity.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/auth_api_model.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../models/auth_hive_model.dart';
import '../../../../core/api/api_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    AuthRemoteDataSource? remote,
    AuthLocalDataSource? local,
  })  : _remote = remote ?? AuthRemoteDataSource(),
        _local = local ?? AuthLocalDataSource();

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final ApiClient _client = ApiClient.I;
  final Connectivity _connectivity = Connectivity();
  static const _profileCacheKey = 'profile_cache_v1';
  static const _sessionCacheKey = 'auth_session_user_v1';

  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    if (result is List<ConnectivityResult>) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }

  @override
  Future<AuthResponse> registerUser(AuthEntity user) async {
    final payload = {
      'fullName': user.fullName,
      'email': user.email,
      'countryCode': user.country ?? '',
      'phone': user.phone,
      'password': user.password ?? '',
      'confirmPassword': user.password ?? '',
    };
    final online = await _isOnline();
    if (!online) {
      await _local.registerUser(_toHive(user));
      await _client.saveToken('local-${user.email}');
      final offlineUser = _offlineEntity(user);
      await _cacheUserState(offlineUser);
      return AuthResponse.success(offlineUser, message: "Registered locally (offline)");
    }
    try {
      final AuthApiModel res = await _remote.registerUser(payload);
      await _client.saveToken(res.token);
      await _local.registerUser(
        _toHive(_withPassword(user, (user.password ?? payload['password'] ?? '').toString())),
      );
      final registeredUser = res.toEntity();
      await _cacheUserState(registeredUser);
      return AuthResponse.success(registeredUser, message: "Registered successfully");
    } on DioException catch (e) {
      if (_isConnectionIssue(e)) {
        await _local.registerUser(_toHive(user));
        await _client.saveToken('local-${user.email}');
        final offlineUser = _offlineEntity(user);
        await _cacheUserState(offlineUser);
        return AuthResponse.success(offlineUser, message: "Registered locally (offline)");
      }
      rethrow;
    }
  }

  @override
  Future<AuthResponse> loginUser(String email, String password) async {
    final online = await _isOnline();
    if (!online) {
      final local = await _local.loginUser(email, password);
      if (local == null) {
        return AuthResponse.failure("Offline login failed: user not found");
      }
      await _client.saveToken('local-$email');
      final offlineUser = _fromHive(local);
      await _cacheUserState(offlineUser);
      return AuthResponse.success(offlineUser, message: "Logged in (offline)");
    }
    try {
      final AuthApiModel res = await _remote.loginUser(email, password);
      await _client.saveToken(res.token);
      // Persist for offline login using provided password
      final apiUser = res.toEntity();
      await _local.registerUser(_toHive(_withPassword(apiUser, password)));
      await _cacheUserState(apiUser);
      return AuthResponse.success(apiUser, message: "Logged in");
    } on DioException catch (e) {
      // Treat connection/timeout as offline and fallback quietly
      if (_isConnectionIssue(e)) {
        final local = await _local.loginUser(email, password);
        if (local != null) {
          await _client.saveToken('local-$email');
          final offlineUser = _fromHive(local);
          await _cacheUserState(offlineUser);
          return AuthResponse.success(offlineUser, message: "Logged in (offline cache)");
        }
        return AuthResponse.failure("Offline login failed: user not found");
      }
      rethrow;
    } catch (e) {
      // Fallback to local if available
      final local = await _local.loginUser(email, password);
      if (local != null) {
        await _client.saveToken('local-$email');
        final offlineUser = _fromHive(local);
        await _cacheUserState(offlineUser);
        return AuthResponse.success(offlineUser, message: "Logged in (offline cache)");
      }
      rethrow;
    }
  }

  AuthEntity _offlineEntity(AuthEntity user) => AuthEntity(
        id: user.email,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        country: user.country,
        bio: user.bio,
        role: 'user',
        profilePic: null,
        savedUniversities: const [],
        token: 'local-${user.email}',
      );

  AuthHiveModel _toHive(AuthEntity user) => AuthHiveModel(
        fullName: user.fullName,
        email: user.email,
        password: user.password ?? '',
        phone: user.phone,
        education: user.bio ?? '',
      );

  AuthEntity _fromHive(AuthHiveModel hive) => AuthEntity(
        id: hive.email,
        fullName: hive.fullName,
        email: hive.email,
        phone: hive.phone,
        country: hive.education,
        bio: hive.education,
        role: 'user',
        savedUniversities: const [],
        token: 'local-${hive.email}',
      );

  AuthEntity _withPassword(AuthEntity entity, String password) => AuthEntity(
        id: entity.id,
        fullName: entity.fullName,
        email: entity.email,
        phone: entity.phone,
        country: entity.country,
        bio: entity.bio,
        role: entity.role,
        profilePic: entity.profilePic,
        savedUniversities: entity.savedUniversities,
        token: entity.token,
        password: password,
      );

  bool _isConnectionIssue(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.unknown;
  }

  Future<void> _cacheUserState(AuthEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = <String, dynamic>{
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'country': user.country ?? '',
      'bio': user.bio ?? '',
      'profilePic': user.profilePic,
      'role': user.role,
      'savedUniversities': user.savedUniversities,
    };
    await prefs.setString(_profileCacheKey, jsonEncode(profile));
    await prefs.setString(_sessionCacheKey, jsonEncode(profile));
  }
}
