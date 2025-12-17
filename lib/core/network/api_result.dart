/// Unified API result wrapper for consistent error handling across the app
class ApiResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;
  final int? statusCode;
  final ApiErrorType? errorType;

  ApiResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.statusCode,
    this.errorType,
  });

  /// Create a successful result
  factory ApiResult.success(T data) {
    return ApiResult._(isSuccess: true, data: data);
  }

  /// Create a failure result with error details
  factory ApiResult.failure(
    String message, {
    int? statusCode,
    ApiErrorType? errorType,
  }) {
    return ApiResult._(
      isSuccess: false,
      errorMessage: message,
      statusCode: statusCode,
      errorType: errorType ?? ApiErrorType.unknown,
    );
  }

  /// Create a network error result
  factory ApiResult.networkError([String? message]) {
    return ApiResult._(
      isSuccess: false,
      errorMessage: message ?? '네트워크 연결을 확인해주세요.',
      errorType: ApiErrorType.network,
    );
  }

  /// Create an authentication error result
  factory ApiResult.authError([String? message]) {
    return ApiResult._(
      isSuccess: false,
      errorMessage: message ?? '인증이 만료되었습니다. 다시 로그인해주세요.',
      statusCode: 401,
      errorType: ApiErrorType.authentication,
    );
  }

  /// Create a validation error result
  factory ApiResult.validationError(String message) {
    return ApiResult._(
      isSuccess: false,
      errorMessage: message,
      statusCode: 400,
      errorType: ApiErrorType.validation,
    );
  }

  /// Create a server error result
  factory ApiResult.serverError([String? message]) {
    return ApiResult._(
      isSuccess: false,
      errorMessage: message ?? '서버 오류가 발생했습니다.',
      statusCode: 500,
      errorType: ApiErrorType.server,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResult.success($data)';
    } else {
      return 'ApiResult.failure($errorMessage)';
    }
  }
}

/// Types of API errors for better error categorization
enum ApiErrorType {
  network,
  authentication,
  validation,
  server,
  timeout,
  unknown,
}