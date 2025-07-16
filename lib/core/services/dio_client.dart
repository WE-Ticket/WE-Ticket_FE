import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';

class DioClient {
  late Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: ApiConstants.defaultHeaders,
      ),
    );

    // 로깅 인터셉터 추가
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );
  }

  Dio get dio => _dio;

  // GET 요청
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST 요청
  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 에러 처리
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '연결 시간이 초과되었습니다.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return '요청한 데이터를 찾을 수 없습니다.';
        } else if (statusCode == 500) {
          return '서버 오류가 발생했습니다.';
        }
        return '서버 오류: $statusCode';
      case DioExceptionType.cancel:
        return '요청이 취소되었습니다.';
      case DioExceptionType.unknown:
        return '네트워크 연결을 확인해주세요.';
      default:
        return '알 수 없는 오류가 발생했습니다.';
    }
  }
}
