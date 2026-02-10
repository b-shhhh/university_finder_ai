import 'auth_entity.dart';

class AuthResponse {
  final bool success;
  final String message;
  final AuthEntity? user;

  AuthResponse({
    required this.success,
    required this.message,
    this.user,
  });

  /// Success factory
  factory AuthResponse.success(AuthEntity user, {String? message}) {
    return AuthResponse(
      success: true,
      user: user,
      message: message ?? 'Operation successful',
    );
  }

  /// Failure factory
  factory AuthResponse.failure(String message) {
    return AuthResponse(
      success: false,
      user: null,
      message: message,
    );
  }
}
