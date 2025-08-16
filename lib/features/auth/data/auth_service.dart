import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:we_ticket/core/constants/api_constants.dart';
import 'package:we_ticket/core/network/dio_client.dart';
import 'package:we_ticket/core/network/api_result.dart';
import 'package:we_ticket/core/utils/app_logger.dart';
import 'package:we_ticket/features/auth/data/auth_validators.dart';
import 'package:we_ticket/features/auth/data/user_models.dart';

class AuthService {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  /// 로그인
  Future<ApiResult<LoginResponse>> login({
    required String loginId,
    required String password,
  }) async {
    try {
      AppLogger.auth('로그인 시도 시작 (아이디: $loginId)');

      // 기본 입력 검증
      final validation = AuthValidators.validateLoginData(
        loginId: loginId,
        password: password,
      );

      if (!validation.isValid) {
        return ApiResult.validationError(validation.firstError!);
      }

      final request = LoginRequest(
        loginId: loginId.trim(),
        loginPassword: password,
      );

      final response = await _dioClient.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(response.data);

        final accessToken = loginResponse.accessToken;
        final refreshToken = loginResponse.refreshToken;

        // 1. DioClient에 설정
        await _dioClient.setAccessToken(accessToken);
        await _dioClient.setRefreshToken(refreshToken);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        
        AppLogger.auth('토큰 저장 완료 - Access: ${accessToken.substring(0, 20)}..., Refresh: ${refreshToken.substring(0, 20)}...');

        AppLogger.success('로그인 성공: 사용자 ID ${loginResponse.userId}', 'AUTH');
        return ApiResult.success(loginResponse);
      } else {
        return ApiResult.failure(
          '로그인 요청 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '로그인');
    } catch (e) {
      AppLogger.error('로그인 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// 회원가입
  Future<ApiResult<SignupResponse>> signup({
    required String fullName,
    required String loginId,
    required String phoneNumber,
    required String password,
    required bool agreeTerms,
    required bool agreePrivacy,
  }) async {
    try {
      AppLogger.auth('회원가입 시도 시작 (아이디: $loginId)');

      final validation = AuthValidators.validateSignupData(
        fullName: fullName,
        loginId: loginId,
        phoneNumber: phoneNumber,
        password: password,
        agreeTerms: agreeTerms,
        agreePrivacy: agreePrivacy,
      );

      if (!validation.isValid) {
        return ApiResult.validationError(validation.firstError!);
      }

      final currentDate = DateTime.now().toIso8601String().split('T')[0];
      final agreements = <Agreement>[];

      if (agreeTerms) {
        agreements.add(
          Agreement(
            termType: 'SERVICE_TERMS',
            agreed: true,
            agreedAt: currentDate,
          ),
        );
      }

      if (agreePrivacy) {
        agreements.add(
          Agreement(
            termType: 'PRIVACY_POLICY',
            agreed: true,
            agreedAt: currentDate,
          ),
        );
      }

      final request = SignupRequest(
        fullName: fullName.trim(),
        loginId: loginId.trim(),
        phoneNumber: phoneNumber.trim(),
        password: password,
        agreements: agreements,
      );

      AppLogger.debug('Signup request: ${request.toString()}', 'AUTH');

      final response = await _dioClient.post(
        ApiConstants.signup,
        data: request.toJson(),
      );

      AppLogger.debug('Signup response: ${response.toString()}', 'AUTH');

      if (response.statusCode == 201) {
        final signupResponse = SignupResponse.fromJson(response.data);
        AppLogger.success('회원가입 성공', 'AUTH');
        return ApiResult.success(signupResponse);
      } else {
        return ApiResult.failure(
          '회원가입 요청 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '회원가입');
    } catch (e) {
      AppLogger.error('회원가입 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> loadUserAuthLevel(int userId) async {
    try {
      AppLogger.auth('인증 사용자 - 아이디: $userId');

      final response = await _dioClient.post(
        ApiConstants.loadUserAuthLevel,
        data: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        // 응답 데이터를 Map으로 직접 반환
        final Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;

        AppLogger.success('인증 레벨 조회 성공: $responseData', 'AUTH');

        return ApiResult.success(responseData);
      } else {
        return ApiResult.failure(
          '인증 조회 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '인증 조회');
    } catch (e) {
      AppLogger.error('인증 조회 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다: $e');
    }
  }

  ApiResult<T> _handleDioError<T>(DioException e, String action) {
    AppLogger.error(
      '$action DioException: ${e.response?.statusCode}',
      e,
      null,
      'AUTH',
    );

    if (e.response?.statusCode == 400) {
      if (action == '로그인') {
        // Parse specific error message from response if available
        final errorData = e.response?.data;
        if (errorData != null && errorData is Map<String, dynamic>) {
          final errorMessage =
              errorData['error'] ?? errorData['message'] ?? errorData['detail'];
          if (errorMessage != null) {
            return ApiResult.validationError(errorMessage.toString());
          }
        }
        return ApiResult.validationError('로그인 정보가 올바르지 않습니다');
      } else {
        return ApiResult.validationError('입력 정보를 확인해주세요');
      }
    } else if (e.response?.statusCode == 409) {
      return ApiResult.failure('이미 사용 중인 아이디이거나 휴대폰 번호입니다', statusCode: 409);
    } else {
      return ApiResult.networkError('네트워크 오류가 발생했습니다');
    }
  }
}

//FIXME
/// AuthService Extension - OmniOne 인증 처리
extension AuthServiceExtension on AuthService {
  /// 본인인증 결과 기록
  Future<ApiResult<IdentityVerificationResponse>> recordIdentityVerification({
    required int userId,
    required String nextVerificationLevel,
    required bool isSuccess,
    required String verificationResult,
  }) async {
    try {
      AppLogger.auth(
        '본인인증 결과 기록 시작 (사용자 ID: $userId, 다음 Auth level: $nextVerificationLevel)',
      );

      final request = IdentityVerificationRequest(
        userId: userId,
        nextVerificationLevel: nextVerificationLevel,
        isSuccess: isSuccess,
        verificationResult: verificationResult,
      );

      final response = await _dioClient.post(
        '/users/identity-verification-record/',
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final verificationResponse = IdentityVerificationResponse.fromJson(
          response.data,
        );
        AppLogger.success(
          '본인인증 기록 성공: ${verificationResponse.message}',
          'AUTH',
        );
        return ApiResult.success(verificationResponse);
      } else {
        return ApiResult.failure(
          '본인인증 기록 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '본인인증 기록');
    } catch (e) {
      AppLogger.error('본인인증 기록 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// OmniOne CX 인증 결과 처리
  Future<ApiResult<IdentityVerificationResponse>> processOmniOneResult({
    required int userId,
    required int currentAuthLevel,
    required Map<String, dynamic> omniOneResult,
  }) async {
    try {
      AppLogger.auth('OmniOne CX 결과 처리 시작');
      AppLogger.debug('현재 레벨: $currentAuthLevel', 'AUTH');

      // OmniOne 결과에서 기본 정보 추출
      final success = omniOneResult['success'] as bool? ?? false;
      final rawData = omniOneResult['data'];

      if (!success) {
        return ApiResult.failure('인증이 실패했습니다.');
      }
      // 현재 레벨을 기준으로 다음 레벨 결정
      final String nextVerificationLevel;
      switch (currentAuthLevel) {
        case 0: // none -> general
          nextVerificationLevel = "general";
          break;
        case 1: // general -> mobile_id  
          nextVerificationLevel = 'mobile_id';
          break;
        default:
          // 이미 최고 레벨이거나 예상치 못한 레벨
          nextVerificationLevel = 'mobile_id';
      }
      
      AppLogger.info('레벨 전환: $currentAuthLevel -> $nextVerificationLevel', 'AUTH');

      // rawData가 String인 경우 JSON 파싱
      Map<String, dynamic> dataMap;
      if (rawData is String) {
        try {
          dataMap = jsonDecode(rawData) as Map<String, dynamic>;
        } catch (e) {
          AppLogger.error('JSON 파싱 실패', e, null, 'AUTH');
          return ApiResult.failure('인증 데이터 파싱에 실패했습니다.');
        }
      } else if (rawData is Map<String, dynamic>) {
        dataMap = rawData;
      } else {
        return ApiResult.validationError('잘못된 인증 데이터 형식입니다.');
      }

      String verificationResult = dataMap['token'];

      return await recordIdentityVerification(
        userId: userId,
        nextVerificationLevel: nextVerificationLevel,
        isSuccess: success,
        verificationResult: verificationResult,
      );
    } catch (e) {
      AppLogger.error('OmniOne 결과 처리 오류', e, null, 'AUTH');
      return ApiResult.failure('인증 결과 처리 중 오류가 발생했습니다: $e');
    }
  }
}
