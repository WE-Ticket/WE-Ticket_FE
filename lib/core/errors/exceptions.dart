/// Base class for all exceptions in the application
/// These are converted to Failures at the repository layer
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const AppException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => 'AppException: $message';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

/// Server-related exceptions (5xx errors)
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

/// Authentication/Authorization exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

/// Validation exceptions (400, invalid input)
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    super.statusCode,
    super.errorCode,
    this.fieldErrors,
  });
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

/// Business logic exceptions
class BusinessLogicException extends AppException {
  const BusinessLogicException({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}