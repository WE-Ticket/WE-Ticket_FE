import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:we_ticket/core/constants/api_constants.dart';
import 'package:we_ticket/core/network/dio_client.dart';
import 'package:we_ticket/core/network/api_result.dart';
import 'package:we_ticket/core/utils/app_logger.dart';
import 'package:we_ticket/core/mixins/api_error_handler_mixin.dart';
import 'package:we_ticket/features/auth/data/auth_validators.dart';
import 'package:we_ticket/features/auth/data/user_models.dart';

class AuthService with ApiErrorHandlerMixin {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  // DioClient getter 추가 (AuthRepositoryImpl에서 사용)
  DioClient get dioClient => _dioClient;

  /// 로그인
  Future<ApiResult<LoginResponse>> login({
    required String loginId,
    required String password,
  }) async {
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

    final result = await _dioClient.postResult<LoginResponse>(
      ApiConstants.login,
      data: request.toJson(),
      parser: (data) {
        final loginResponse = LoginResponse.fromJson(data);
        return loginResponse;
      },
    );

    if (result.isSuccess && result.data != null) {
      final loginResponse = result.data!;
      final accessToken = loginResponse.accessToken;
      final refreshToken = loginResponse.refreshToken;

      // DioClient에 토큰 설정
      await _dioClient.setAccessToken(accessToken);
      await _dioClient.setRefreshToken(refreshToken);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);

      AppLogger.success('로그인 성공: 사용자 ID ${loginResponse.userId}', 'AUTH');
    }

    return result;
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

  /// AuthService 전용 DioException 에러 처리 (409 특별 처리 포함)
  ApiResult<T> _handleDioError<T>(DioException e, String action) {
    final statusCode = e.response?.statusCode;
    final errorData = e.response?.data;

    // 409 Conflict 특별 처리 (AuthService만의 특별 로직)
    if (statusCode == 409 && errorData is Map<String, dynamic>) {
      final errorCode = errorData['error_code'];
      final existingLoginId = errorData['existing_login_id'];

      if (errorCode == 'duplicated_ci' && existingLoginId != null) {
        AppLogger.error('본인인증 중복 오류', errorData, null, 'AUTH');
        return ApiResult.failure(
          'WE-Ticket은 하나의 계정에서만 본인인증이 가능합니다.\n\n'
          '다음 계정에서 본인인증이 되어있음이 확인되었습니다:\n'
          '- 계정 아이디: $existingLoginId\n\n'
          '해당 계정으로 다시 재로그인 후 본인인증 및 서비스를 이용해주세요.\n'
          '기타 문의사항은 고객센터로 연락해주시기 바랍니다.',
          statusCode: 409,
        );
      }
    }

    // 일반적인 에러 처리는 믹스인 사용
    return handleDioError<T>(e, action, 'AUTH');
  }

  /// 아이디 찾기 - 전화번호로 인증코드 요청
  Future<ApiResult<FindIdResponse>> findId({
    required String phoneNumber,
  }) async {
    try {
      AppLogger.auth('아이디 찾기 시작 (전화번호: $phoneNumber)');

      final request = FindIdRequest(phoneNumber: phoneNumber);

      final response = await _dioClient.post(
        '/users/find-id/',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final findIdResponse = FindIdResponse.fromJson(response.data);
        AppLogger.success('아이디 찾기 인증코드 발송 완료', 'AUTH');
        return ApiResult.success(findIdResponse);
      } else if (response.statusCode == 404) {
        return ApiResult.failure('해당 전화번호의 회원이 없습니다.');
      } else {
        return ApiResult.failure(
          '아이디 찾기 요청 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '아이디 찾기');
    } catch (e) {
      AppLogger.error('아이디 찾기 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// 아이디 인증 - 인증코드 확인 후 아이디 반환
  Future<ApiResult<VerifyIdResponse>> verifyId({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      AppLogger.auth('아이디 인증 시작');

      final request = VerifyIdRequest(phoneNumber: phoneNumber, code: code);

      final response = await _dioClient.post(
        '/users/verify-id/',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final verifyIdResponse = VerifyIdResponse.fromJson(response.data);
        AppLogger.success('아이디 인증 성공: ${verifyIdResponse.loginId}', 'AUTH');
        return ApiResult.success(verifyIdResponse);
      } else if (response.statusCode == 404) {
        return ApiResult.failure('사용자를 찾을 수 없습니다.');
      } else if (response.statusCode == 400) {
        return ApiResult.failure('인증코드가 올바르지 않거나 만료되었습니다.');
      } else {
        return ApiResult.failure(
          '아이디 인증 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '아이디 인증');
    } catch (e) {
      AppLogger.error('아이디 인증 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// 비밀번호 찾기 - 전화번호와 아이디로 인증코드 요청
  Future<ApiResult<FindPasswordResponse>> findPassword({
    required String phoneNumber,
    required String loginId,
  }) async {
    try {
      AppLogger.auth('비밀번호 찾기 시작 (아이디: $loginId)');

      final request = FindPasswordRequest(
        phoneNumber: phoneNumber,
        loginId: loginId,
      );

      final response = await _dioClient.post(
        '/users/find-password/',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final findPasswordResponse = FindPasswordResponse.fromJson(
          response.data,
        );
        AppLogger.success('비밀번호 찾기 인증코드 발송 완료', 'AUTH');
        return ApiResult.success(findPasswordResponse);
      } else if (response.statusCode == 404) {
        return ApiResult.failure('사용자를 찾을 수 없습니다.');
      } else {
        return ApiResult.failure(
          '비밀번호 찾기 요청 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '비밀번호 찾기');
    } catch (e) {
      AppLogger.error('비밀번호 찾기 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// 비밀번호 재설정 인증 - 인증코드 확인
  Future<ApiResult<VerifyPasswordResponse>> verifyPassword({
    required String phoneNumber,
    required String loginId,
    required String code,
  }) async {
    try {
      AppLogger.auth('비밀번호 재설정 인증 시작');

      final request = VerifyPasswordRequest(
        phoneNumber: phoneNumber,
        loginId: loginId,
        code: code,
      );

      final response = await _dioClient.post(
        '/users/verify-password/',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final verifyPasswordResponse = VerifyPasswordResponse.fromJson(
          response.data,
        );
        AppLogger.success('비밀번호 재설정 인증 성공', 'AUTH');
        return ApiResult.success(verifyPasswordResponse);
      } else if (response.statusCode == 404) {
        return ApiResult.failure('사용자를 찾을 수 없습니다.');
      } else if (response.statusCode == 400) {
        return ApiResult.failure('인증코드가 올바르지 않거나 만료되었습니다.');
      } else {
        return ApiResult.failure(
          '비밀번호 재설정 인증 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '비밀번호 재설정 인증');
    } catch (e) {
      AppLogger.error('비밀번호 재설정 인증 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// 비밀번호 재설정 - 새 비밀번호로 변경
  Future<ApiResult<ResetPasswordResponse>> resetPassword({
    required String phoneNumber,
    required String loginId,
    required String newPassword,
  }) async {
    try {
      AppLogger.auth('비밀번호 재설정 시작');

      final request = ResetPasswordRequest(
        phoneNumber: phoneNumber,
        loginId: loginId,
        newPassword: newPassword,
      );

      final response = await _dioClient.post(
        '/users/reset-password/',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final resetPasswordResponse = ResetPasswordResponse.fromJson(
          response.data,
        );
        AppLogger.success('비밀번호 재설정 완료', 'AUTH');
        return ApiResult.success(resetPasswordResponse);
      } else if (response.statusCode == 404) {
        return ApiResult.failure('사용자를 찾을 수 없습니다.');
      } else if (response.statusCode == 400) {
        return ApiResult.failure('인증이 완료되지 않았습니다.');
      } else {
        return ApiResult.failure(
          '비밀번호 재설정 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '비밀번호 재설정');
    } catch (e) {
      AppLogger.error('비밀번호 재설정 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// 로그인 아이디 중복 확인
  Future<ApiResult<LoginIdCheckResponse>> checkLoginId({
    required String loginId,
  }) async {
    try {
      AppLogger.auth('로그인 아이디 중복 확인: $loginId');

      final response = await _dioClient.get(
        '/users/check-login-id/',
        queryParameters: {'login_id': loginId},
      );

      if (response.statusCode == 200) {
        final checkResponse = LoginIdCheckResponse.fromJson(response.data);
        AppLogger.success(
          '아이디 중복 확인 완료: ${checkResponse.isDuplicate ? '중복됨' : '사용가능'}',
          'AUTH',
        );
        return ApiResult.success(checkResponse);
      } else {
        return ApiResult.failure(
          '아이디 중복 확인 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '아이디 중복 확인');
    } catch (e) {
      AppLogger.error('아이디 중복 확인 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// 전화번호 중복 확인
  Future<ApiResult<PhoneNumberCheckResponse>> checkPhoneNumber({
    required String phoneNumber,
  }) async {
    try {
      AppLogger.auth('전화번호 중복 확인: $phoneNumber');

      final response = await _dioClient.get(
        '/users/check-phone-number/',
        queryParameters: {'phone_number': phoneNumber},
      );

      if (response.statusCode == 200) {
        final checkResponse = PhoneNumberCheckResponse.fromJson(response.data);
        AppLogger.success(
          '전화번호 중복 확인 완료: ${checkResponse.isDuplicate ? '중복됨' : '사용가능'}',
          'AUTH',
        );
        return ApiResult.success(checkResponse);
      } else {
        return ApiResult.failure(
          '전화번호 중복 확인 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '전화번호 중복 확인');
    } catch (e) {
      AppLogger.error('전화번호 중복 확인 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// 회원 탈퇴
  Future<ApiResult<void>> deleteAccount({required String password}) async {
    try {
      AppLogger.auth('회원 탈퇴 시도');

      final response = await _dioClient.delete(
        '/users/account/delete/',
        data: {'password': password},
      );

      if (response.statusCode == 200) {
        AppLogger.success('회원 탈퇴 성공', 'AUTH');
        return ApiResult.success(null);
      } else {
        return ApiResult.failure(
          '회원 탈퇴 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e, '회원 탈퇴');
    } catch (e) {
      AppLogger.error('회원 탈퇴 오류', e, null, 'AUTH');
      return ApiResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// 사용자 약관 동의 API
  Future<ApiResult<void>> submitUserAgreement({
    required String termType,
  }) async {
    AppLogger.info(
      '사용자 약관 동의 요청 시작 (약관타입: $termType)',
      'AUTH',
    );

    final now = DateTime.now();
    final requestData = {
      'term_type': termType,
      'agreed': true,
      'agreed_at': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    };

    final result = await _dioClient.postResult<void>(
      '/users/vc-agreement/',
      data: requestData,
      parser: (data) {
        AppLogger.success('사용자 약관 동의 완료', 'AUTH');
      },
    );

    return result;
  }
}

/// AuthService Extension - OmniOne 인증 처리
extension AuthServiceExtension on AuthService {
  /// 본인인증 결과 기록
  Future<ApiResult<IdentityVerificationResponse>> recordIdentityVerification({
    required int userId,
    required String nextVerificationLevel,
    required bool isSuccess,
    required String verificationResult,
  }) async {
    AppLogger.auth(
      '본인인증 결과 기록 시작 (사용자 ID: $userId, 다음 Auth level: $nextVerificationLevel)',
    );

    final request = IdentityVerificationRequest(
      userId: userId,
      nextVerificationLevel: nextVerificationLevel,
      isSuccess: isSuccess,
      verificationResult: verificationResult,
    );

    final result = await _dioClient.postResult<IdentityVerificationResponse>(
      '/users/identity-verification-record/',
      data: request.toJson(),
      parser: (data) {
        final verificationResponse = IdentityVerificationResponse.fromJson(data);
        AppLogger.success(
          '본인인증 기록 성공: ${verificationResponse.message}',
          'AUTH',
        );
        return verificationResponse;
      },
    );

    return result;
  }

  /// 동시접속 감지시 세션 만료 처리
  Future<ApiResult<void>> handleConcurrentLoginDetected() async {
    try {
      AppLogger.warning('동시접속 감지 - 세션 만료 처리', 'AUTH');

      // 1. DioClient 토큰 완전 삭제
      await _dioClient.clearTokens();

      // 2. SharedPreferences 정리
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      AppLogger.info('동시접속으로 인한 자동 로그아웃 완료', 'AUTH');
      return ApiResult.success(null);
    } catch (e) {
      AppLogger.error('동시접속 처리 오류', e, null, 'AUTH');
      return ApiResult.failure('세션 정리 중 오류가 발생했습니다');
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

      // 현재 레벨을 기준으로 다음 레벨 결정
      final String nextVerificationLevel;
      // switch (currentAuthLevel) {
      //   case 0: // none -> general
      //     nextVerificationLevel = "general";
      //     break;
      //   case 1: // general -> mobile_id
      //     nextVerificationLevel = 'mobile_id';
      //     break;
      //   default:
      //     // 이미 최고 레벨이거나 예상치 못한 레벨
      //     nextVerificationLevel = 'mobile_id';
      // }

      switch (currentAuthLevel) {
        case 1:
          nextVerificationLevel = 'general';
          break;
        case 2:
          nextVerificationLevel = 'mobile_id';
          break;
        default:
          nextVerificationLevel = 'general';
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
