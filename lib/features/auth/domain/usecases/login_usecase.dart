
import '../../domain/entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<AuthResponse> execute(String email, String password) async {
    return await repository.loginUser(email, password);
  }
}
