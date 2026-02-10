/// Base class for all failures
abstract class Failure {
  final String message;

  const Failure(this.message);
}

/// API / backend related failure
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server failure'])
      : super(message);
}

/// Local storage (Hive / cache) failure
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache failure'])
      : super(message);
}

/// Internet / connectivity failure
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection'])
      : super(message);
}

/// Authentication related failure
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed'])
      : super(message);
}

/// Validation / form failure
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Invalid input'])
      : super(message);
}
