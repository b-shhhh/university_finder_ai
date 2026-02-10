import '../../domain/entities/auth_entity.dart';

abstract class AuthRepository {
  Future<void> registerUser(AuthEntity user);
  Future<AuthEntity?> loginUser(String email, String password);
}
