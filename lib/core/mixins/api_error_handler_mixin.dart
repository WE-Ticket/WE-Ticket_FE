import 'package:dio/dio.dart';
import '../network/api_result.dart';
import '../utils/app_logger.dart';
import '../utils/error_message_parser.dart';

/// 모든 API 서비스에서 사용할 수 있는 공통 에러 처리 믹스인
mixin ApiErrorHandlerMixin {
  /// DioException 에러 처리 (공통)
  ApiResult<T> handleDioError<T>(DioException e, String action, [String? serviceName]) {
    final service = serviceName ?? 'API';
    
    AppLogger.error(
      '$action DioException: ${e.response?.statusCode}',
      e,
      e.stackTrace,
      service,
    );
    AppLogger.error('Error Response Data', e.response?.data, null, service);

    final statusCode = e.response?.statusCode;
    final errorData = e.response?.data;

    // 통합 에러 메시지 파싱
    final errorMessage = ErrorMessageParser.parseErrorMessage(
      errorData,
      getDefaultErrorMessage(statusCode, action),
    );

    // 상태 코드별 처리
    return createApiResult<T>(statusCode, errorMessage);
  }

  /// 상태 코드별 ApiResult 생성
  ApiResult<T> createApiResult<T>(int? statusCode, String errorMessage) {
    switch (statusCode) {
      case 400:
        return ApiResult.validationError(errorMessage);
      case 401:
        return ApiResult.failure(errorMessage, statusCode: 401);
      case 403:
        return ApiResult.failure(errorMessage, statusCode: 403);
      case 404:
        return ApiResult.failure(errorMessage, statusCode: 404);
      case 409:
        return ApiResult.failure(errorMessage, statusCode: 409);
      case 422:
        return ApiResult.validationError(errorMessage);
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiResult.networkError(errorMessage);
      default:
        return ApiResult.networkError(errorMessage);
    }
  }

  /// 상태 코드와 액션에 따른 기본 에러 메시지 반환
  String getDefaultErrorMessage(int? statusCode, String action) {
    switch (statusCode) {
      case 400:
        if (action.contains('로그인')) {
          return '로그인 정보가 올바르지 않습니다';
        }
        return '입력 정보를 확인해주세요';
      case 401:
        return '인증이 필요합니다';
      case 403:
        return '접근 권한이 없습니다';
      case 404:
        return '요청한 정보를 찾을 수 없습니다';
      case 409:
        return '이미 사용 중인 정보입니다';
      case 422:
        return '입력 정보를 다시 확인해주세요';
      case 500:
        return '서버 오류가 발생했습니다';
      case 502:
      case 503:
      case 504:
        return '서버에 연결할 수 없습니다';
      default:
        return '네트워크 오류가 발생했습니다';
    }
  }

  /// 일반 Exception 에러 처리
  ApiResult<T> handleGeneralError<T>(dynamic error, String action, [String? serviceName]) {
    final service = serviceName ?? 'API';
    AppLogger.error('$action 일반 오류', error, null, service);
    return ApiResult.failure('알 수 없는 오류가 발생했습니다');
  }

  /// 서버 응답 상태 코드 기반 에러 처리
  ApiResult<T> handleStatusCodeError<T>(int statusCode, String action, [dynamic responseData]) {
    final errorMessage = ErrorMessageParser.parseErrorMessage(
      responseData,
      getDefaultErrorMessage(statusCode, action),
    );
    
    return createApiResult<T>(statusCode, errorMessage);
  }
}