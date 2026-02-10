import '../../domain/entities/auth_entity.dart';
import '../../domain/entities/auth_response.dart';

abstract class AuthRepository {
  /// Registers a new user
  Future<AuthResponse> registerUser(AuthEntity user);

  /// Logs in a user
  Future<AuthResponse> loginUser(String email, String password);
}
