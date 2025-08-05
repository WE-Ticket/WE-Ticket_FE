import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';

class DioClient {
  late Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: ApiConstants.defaultHeaders,
      ),
    );

    // 🔁 인터셉터 추가
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          _accessToken ??= prefs.getString('access_token');

          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          // access_token 만료 시 refresh_token으로 재발급 시도
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            _refreshToken ??= prefs.getString('refresh_token');

            final success = await _refreshAccessToken();
            if (success) {
              // 요청 재시도
              final retryOptions = error.requestOptions;

              retryOptions.headers['Authorization'] = 'Bearer $_accessToken';

              final cloneResponse = await _dio.fetch(retryOptions);
              return handler.resolve(cloneResponse);
            }
          }

          return handler.next(error);
        },
      ),
    );

    // 📋 로그 인터셉터
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

  /// ✅ 토큰 설정
  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<void> setRefreshToken(String token) async {
    _refreshToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', token);
  }

  /// ✅ 토큰 제거
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  /// ✅ access_token 갱신
  Future<bool> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) return false;

      final response = await _dio.post(
        '/users/token/refresh/', // ⚠️ 실제 서버의 refresh endpoint 확인 필요
        data: {'refresh': _refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        await setAccessToken(newAccessToken);
        return true;
      }
    } catch (e) {
      print('🔁 토큰 갱신 실패: $e');
    }

    return false;
  }

  /// ✅ 기존 요청 함수 유지
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

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '연결 시간이 초과되었습니다.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) return '요청한 데이터를 찾을 수 없습니다.';
        if (statusCode == 500) return '서버 오류가 발생했습니다.';
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
