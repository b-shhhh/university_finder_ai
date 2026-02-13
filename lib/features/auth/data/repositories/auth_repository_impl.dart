import '../../domain/entities/auth_entity.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/auth_api_model.dart';
import '../../../../core/api/api_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthRemoteDataSource? remote})
      : _remote = remote ?? AuthRemoteDataSource();

  final AuthRemoteDataSource _remote;
  final ApiClient _client = ApiClient.I;

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
    final AuthApiModel res = await _remote.registerUser(payload);
    await _client.saveToken(res.token);
    return AuthResponse.success(res.toEntity(), message: "Registered successfully");
  }

  @override
  Future<AuthResponse> loginUser(String email, String password) async {
    final AuthApiModel res = await _remote.loginUser(email, password);
    await _client.saveToken(res.token);
    return AuthResponse.success(res.toEntity(), message: "Logged in");
  }
}
