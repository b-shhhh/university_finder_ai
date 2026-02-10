import '../../domain/entities/auth_entity.dart';

abstract class AuthState {}

/// Initial state
class AuthInitial extends AuthState {}

/// Loading state (e.g., during login or register)
class AuthLoading extends AuthState {}

/// Success state with user data
class AuthSuccess extends AuthState {
  final AuthEntity user;
  final String message;

  AuthSuccess(this.user, {this.message = 'Success'});
}

/// Error state with message
class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
