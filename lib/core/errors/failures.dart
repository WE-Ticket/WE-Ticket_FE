import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Provides a consistent way to handle errors across all layers
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const Failure({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, statusCode, errorCode];
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

/// Server-related failures (5xx errors)
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

/// Authentication/Authorization failures (401, 403)
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

/// Validation failures (400, invalid input)
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.statusCode,
    super.errorCode,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, statusCode, errorCode, fieldErrors];
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

/// Business logic failures
class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

/// Unknown/Unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

/// Technical/Platform failures
class TechnicalFailure extends Failure {
  const TechnicalFailure({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

/// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}