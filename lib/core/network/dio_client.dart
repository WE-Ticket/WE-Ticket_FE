import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_result.dart';
import '../utils/app_logger.dart';

class DioClient {
  late Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false; // 토큰 갱신 중복 방지
  
  // 글로벌 인증 만료 콜백
  static Function(bool isSessionExpired, bool isConcurrentLogin, String? errorMessage)? _authExpiredCallback;
  
  // 동시접속 감지를 위한 변수들
  DateTime? _lastTokenRefreshTime;
  DateTime? _lastSuccessfulRequest;

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
          // ✅ 매번 SharedPreferences에서 최신 토큰 로드
          final prefs = await SharedPreferences.getInstance();
          final storedAccessToken = prefs.getString('access_token');
          final storedRefreshToken = prefs.getString('refresh_token');

          // 메모리 토큰을 최신 상태로 동기화
          _accessToken = storedAccessToken;
          _refreshToken = storedRefreshToken;

          if (_accessToken != null && _accessToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
            AppLogger.auth('요청에 토큰 추가: ${_accessToken!.substring(0, 20)}...');
          } else {
            AppLogger.warning('토큰 없음 - 인증 없이 요청', 'AUTH');
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            AppLogger.warning('🚨 401 에러 감지 - 토큰 상태 확인 후 refresh 시도', 'AUTH');
            
            // 현재 토큰 상태 로깅
            await debugTokenStatus();

            // 토큰 갱신 시도
            final refreshSuccess = await _refreshAccessToken();
            
            if (refreshSuccess) {
              // 토큰 갱신 성공 - 원래 요청 재시도
              AppLogger.success('토큰 갱신 성공 - 요청 재시도', 'AUTH');
              
              // 새로운 토큰으로 헤더 업데이트
              error.requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
              
              // 요청 재시도
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } else {
              // 토큰 갱신 실패 - 에러 분석 후 로그아웃 처리
              AppLogger.error('토큰 갱신 실패 - 로그아웃 처리', null, null, 'AUTH');
              
              // 토큰 완전 삭제
              await clearTokens();

              // 에러 응답에서 상세 정보 추출
              final responseData = error.response?.data;
              String? errorMessage;
              bool isSessionExpired = false;
              bool isConcurrentLogin = false;
              
              if (responseData != null && responseData is Map<String, dynamic>) {
                errorMessage = responseData['message'] ?? responseData['error'] ?? responseData['detail'];
                
                // 동시접속 감지 로직 개선
                final messageStr = errorMessage?.toString().toLowerCase() ?? '';
                
                // 1. 명시적 동시접속 메시지 확인
                if (messageStr.contains('concurrent') || 
                    messageStr.contains('동시') || 
                    messageStr.contains('다른') ||
                    messageStr.contains('duplicate') ||
                    messageStr.contains('multiple') ||
                    messageStr.contains('another') ||
                    messageStr.contains('elsewhere')) {
                  isConcurrentLogin = true;
                }
                // 2. 최근에 토큰 갱신을 했는데도 실패하는 경우 (동시접속 가능성)
                else if (_lastTokenRefreshTime != null && 
                         DateTime.now().difference(_lastTokenRefreshTime!).inMinutes < 5) {
                  AppLogger.warning('최근 토큰 갱신 후 즉시 실패 - 동시접속 의심', 'AUTH');
                  isConcurrentLogin = true;
                }
                // 3. 기본: 세션 만료
                else {
                  isSessionExpired = true;
                }
              } else {
                // 토큰이 아예 없는 상태라면 동시접속보다는 세션 만료
                isSessionExpired = true;
              }

              // 글로벌 인증 만료 이벤트 발생 (토스트 메시지 + 자동 로그아웃)
              _triggerAuthExpiredEvent(isSessionExpired, isConcurrentLogin, errorMessage);
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

  /// ✅ 토큰 설정 - SharedPreferences와 메모리 동기화
  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    AppLogger.auth('Access 토큰 저장 완료');
  }

  Future<void> setRefreshToken(String token) async {
    _refreshToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', token);
    AppLogger.auth('Refresh 토큰 저장 완료');
  }

  /// ✅ 토큰 제거 - 완전한 정리
  Future<void> clearTokens() async {
    AppLogger.auth('모든 토큰 삭제 시작');

    // 메모리에서 삭제
    _accessToken = null;
    _refreshToken = null;

    // SharedPreferences에서 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');

    AppLogger.auth('모든 토큰 삭제 완료');
  }

  /// ✅ access_token 갱신
  Future<bool> _refreshAccessToken() async {
    if (_isRefreshing) {
      AppLogger.warning('토큰 갱신 이미 진행 중', 'AUTH');
      return false;
    }

    _isRefreshing = true;
    
    try {
      AppLogger.auth('토큰 갱신 시작');

      // SharedPreferences에서 최신 refresh 토큰 로드
      final prefs = await SharedPreferences.getInstance();
      final storedRefreshToken = prefs.getString('refresh_token');
      final storedAccessToken = prefs.getString('access_token');

      AppLogger.debug('토큰 상태 확인:', 'AUTH');
      AppLogger.debug('  Access 토큰: ${storedAccessToken?.substring(0, 20) ?? 'null'}...', 'AUTH');
      AppLogger.debug('  Refresh 토큰: ${storedRefreshToken?.substring(0, 20) ?? 'null'}...', 'AUTH');

      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        AppLogger.error('Refresh 토큰 없음 - 로그인 필요', null, null, 'AUTH');
        return false;
      }

      _refreshToken = storedRefreshToken;

      final response = await _dio.post(
        '/users/token/refresh/',
        data: {'refresh': _refreshToken},
        options: Options(
          headers: {
            'Authorization': null, // refresh 요청 시에는 기존 토큰 제거
          },
        ),
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        await setAccessToken(newAccessToken);

        // refresh 토큰도 새로 발급된 경우
        final newRefreshToken = response.data['refresh'];
        if (newRefreshToken != null) {
          await setRefreshToken(newRefreshToken);
        }

        // 토큰 갱신 시간 기록
        _lastTokenRefreshTime = DateTime.now();
        
        AppLogger.success('토큰 갱신 성공', 'AUTH');
        return true;
      } else {
        AppLogger.error('토큰 갱신 응답 오류: ${response.statusCode}', null, null, 'AUTH');
        return false;
      }
    } catch (e) {
      AppLogger.error('토큰 갱신 예외', e, null, 'AUTH');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// ✅ 토큰 상태 확인
  Future<bool> hasValidTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');

    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  /// ✅ 현재 토큰 정보 출력 (디버깅용)
  Future<void> debugTokenStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final storedAccess = prefs.getString('access_token');
    final storedRefresh = prefs.getString('refresh_token');

    AppLogger.debug('토큰 상태 디버그:', 'AUTH');
    AppLogger.debug('  메모리 Access: ${_accessToken?.substring(0, 20) ?? 'null'}...', 'AUTH');
    AppLogger.debug('  저장된 Access: ${storedAccess?.substring(0, 20) ?? 'null'}...', 'AUTH');
    AppLogger.debug('  메모리 Refresh: ${_refreshToken?.substring(0, 20) ?? 'null'}...', 'AUTH');
    AppLogger.debug('  저장된 Refresh: ${storedRefresh?.substring(0, 20) ?? 'null'}...', 'AUTH');
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
        if (statusCode == 401) return '인증이 만료되었습니다. 다시 로그인해주세요.';
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

  /// New methods that return ApiResult instead of throwing exceptions
  
  /// GET request that returns ApiResult
  Future<ApiResult<T>> getResult<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? parser,
  }) async {
    try {
      AppLogger.apiRequest('GET', path, queryParameters);
      final response = await _dio.get(path, queryParameters: queryParameters);
      
      AppLogger.apiResponse(path, response.statusCode ?? 0, response.data);
      
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = parser != null ? parser(response.data) : response.data as T;
        return ApiResult.success(data);
      } else {
        return ApiResult.failure(
          'Request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('GET request failed', e, null, 'API');
      return _handleDioException(e);
    } catch (e) {
      AppLogger.error('Unexpected error in GET request', e, null, 'API');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// POST request that returns ApiResult
  Future<ApiResult<T>> postResult<T>(
    String path, {
    Map<String, dynamic>? data,
    T Function(dynamic data)? parser,
  }) async {
    try {
      AppLogger.apiRequest('POST', path, data);
      final response = await _dio.post(path, data: data);
      
      AppLogger.apiResponse(path, response.statusCode ?? 0, response.data);
      
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        final responseData = parser != null ? parser(response.data) : response.data as T;
        return ApiResult.success(responseData);
      } else {
        return ApiResult.failure(
          'Request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('POST request failed', e, null, 'API');
      return _handleDioException(e);
    } catch (e) {
      AppLogger.error('Unexpected error in POST request', e, null, 'API');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 글로벌 인증 만료 콜백 설정
  static void setAuthExpiredCallback(Function(bool isSessionExpired, bool isConcurrentLogin, String? errorMessage) callback) {
    _authExpiredCallback = callback;
  }

  /// 인증 만료 이벤트 발생
  void _triggerAuthExpiredEvent(bool isSessionExpired, bool isConcurrentLogin, String? errorMessage) {
    if (_authExpiredCallback != null) {
      _authExpiredCallback!(isSessionExpired, isConcurrentLogin, errorMessage);
    }
  }

  /// Convert DioException to ApiResult
  ApiResult<T> _handleDioException<T>(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResult.failure(
          '연결 시간이 초과되었습니다.',
          errorType: ApiErrorType.timeout,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return ApiResult.authError();
        } else if (statusCode == 400) {
          return ApiResult.validationError('입력 정보를 확인해주세요.');
        } else if (statusCode == 404) {
          return ApiResult.failure(
            '요청한 데이터를 찾을 수 없습니다.',
            statusCode: statusCode,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ApiResult.serverError();
        }
        return ApiResult.failure(
          '서버 오류: $statusCode',
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return ApiResult.failure('요청이 취소되었습니다.');
      case DioExceptionType.unknown:
        return ApiResult.networkError();
      default:
        return ApiResult.failure('알 수 없는 오류가 발생했습니다.');
    }
  }
}
