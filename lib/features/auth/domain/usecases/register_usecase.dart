import '../../domain/entities/auth_entity.dart';
import '../../domain/entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase({required this.repository});

  Future<AuthResponse> execute(AuthEntity user) async {
    return await repository.registerUser(user);
  }
}
