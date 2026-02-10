/// Base class for all custom exceptions
abstract class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

/// Thrown when API call fails
class ServerException extends AppException {
  const ServerException([String message = 'Server error occurred'])
      : super(message);
}

/// Thrown when cached/local data is not found
class CacheException extends AppException {
  const CacheException([String message = 'Cache data not found'])
      : super(message);
}

/// Thrown when user is unauthorized
class UnauthorizedException extends AppException {
  const UnauthorizedException([String message = 'Unauthorized access'])
      : super(message);
}

/// Thrown when no internet connection is available
class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection'])
      : super(message);
}

/// Thrown when input validation fails
class ValidationException extends AppException {
  const ValidationException([String message = 'Invalid input'])
      : super(message);
}
