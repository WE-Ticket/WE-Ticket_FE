import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_ticket/features/auth/data/auth_validators.dart';
import 'package:we_ticket/features/auth/data/user_models.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class AuthService {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  /// 로그인
  Future<AuthResult<LoginResponse>> login({
    required String loginId,
    required String password,
  }) async {
    try {
      print('🔐 로그인 시도 시작 (아이디: $loginId)');

      // 기본 입력 검증
      final validation = AuthValidators.validateLoginData(
        loginId: loginId,
        password: password,
      );

      if (!validation.isValid) {
        return AuthResult.failure(validation.firstError!);
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

        print('✅ 로그인 성공: 사용자 ID ${loginResponse.userId}');
        return AuthResult.success(loginResponse);
      } else {
        return AuthResult.failure('로그인 요청 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return _handleDioError(e, '로그인');
    } catch (e) {
      print('❌ 로그인 오류: $e');
      return AuthResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// 회원가입
  Future<AuthResult<SignupResponse>> signup({
    required String fullName,
    required String loginId,
    required String phoneNumber,
    required String password,
    required bool agreeTerms,
    required bool agreePrivacy,
  }) async {
    try {
      print('📝 회원가입 시도 시작 (아이디: $loginId)');

      final validation = AuthValidators.validateSignupData(
        fullName: fullName,
        loginId: loginId,
        phoneNumber: phoneNumber,
        password: password,
        agreeTerms: agreeTerms,
        agreePrivacy: agreePrivacy,
      );

      if (!validation.isValid) {
        return AuthResult.failure(validation.firstError!);
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

      print(request);

      final response = await _dioClient.post(
        ApiConstants.signup,
        data: request.toJson(),
      );

      print(response);

      if (response.statusCode == 201) {
        final signupResponse = SignupResponse.fromJson(response.data);
        print('✅ 회원가입 성공');
        return AuthResult.success(signupResponse);
      } else {
        return AuthResult.failure('회원가입 요청 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return _handleDioError(e, '회원가입');
    } catch (e) {
      print('❌ 회원가입 오류: $e');
      return AuthResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  Future<AuthResult<Map<String, dynamic>>> loadUserAuthLevel(int userId) async {
    try {
      print('인증 사용자 - 아이디: $userId');

      final response = await _dioClient.post(
        ApiConstants.loadUserAuthLevel,
        data: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        // 응답 데이터를 Map으로 직접 반환
        final Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;

        print('✅ 인증 레벨 조회 성공: $responseData');

        return AuthResult.success(responseData);
      } else {
        return AuthResult.failure('인증 조회 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return _handleDioError(e, '인증 조회');
    } catch (e) {
      print('❌ 인증 조회 오류: $e');
      return AuthResult.failure('알 수 없는 오류가 발생했습니다: $e');
    }
  }

  AuthResult<T> _handleDioError<T>(DioException e, String action) {
    print('❌ $action DioException: ${e.response?.statusCode}');

    if (e.response?.statusCode == 400) {
      if (action == '로그인') {
        // FIXME: 400일 때, 에러 메시지 error 두개로 분기 되어서 전달됨. (존재X 아이디, 비밀번호 오류)
        return AuthResult.failure('로그인 정보가 올바르지 않습니다');
      } else {
        return AuthResult.failure('입력 정보를 확인해주세요');
      }
    } else if (e.response?.statusCode == 409) {
      return AuthResult.failure('이미 사용 중인 아이디이거나 휴대폰 번호입니다');
    } else {
      return AuthResult.failure('네트워크 오류가 발생했습니다');
    }
  }
}

/// 인증 결과 래퍼 클래스
class AuthResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  AuthResult._({required this.isSuccess, this.data, this.errorMessage});

  /// 성공 결과 생성
  factory AuthResult.success(T data) {
    return AuthResult._(isSuccess: true, data: data);
  }

  /// 실패 결과 생성
  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'AuthResult.success($data)';
    } else {
      return 'AuthResult.failure($errorMessage)';
    }
  }
}

//FIXME
/// AuthService Extension - OmniOne 인증 처리
extension AuthServiceExtension on AuthService {
  /// 본인인증 결과 기록
  Future<AuthResult<IdentityVerificationResponse>> recordIdentityVerification({
    required int userId,
    required String nextVerificationLevel,
    required bool isSuccess,
    required String verificationResult,
  }) async {
    try {
      print(
        '🔐 본인인증 결과 기록 시작 (사용자 ID: $userId, 다음 Auth level: $nextVerificationLevel)',
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
        print('✅ 본인인증 기록 성공: ${verificationResponse.message}');
        return AuthResult.success(verificationResponse);
      } else {
        return AuthResult.failure('본인인증 기록 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return _handleDioError(e, '본인인증 기록');
    } catch (e) {
      print('❌ 본인인증 기록 오류: $e');
      return AuthResult.failure('알 수 없는 오류가 발생했습니다');
    }
  }

  /// OmniOne CX 인증 결과 처리
  Future<AuthResult<IdentityVerificationResponse>> processOmniOneResult({
    required int userId,
    required Map<String, dynamic> omniOneResult,
  }) async {
    try {
      print('🔐 OmniOne CX 결과 처리 시작');
      print('📋 인증 타입: ${omniOneResult['authType']}');

      // OmniOne 결과에서 기본 정보 추출
      final authType = omniOneResult['authType'] as String? ?? 'unknown';
      final success = omniOneResult['success'] as bool? ?? false;
      final rawData = omniOneResult['data'];

      if (!success) {
        return AuthResult.failure('인증이 실패했습니다.');
      }
      final String nextVerificationLevel;
      switch (authType) {
        case 'simple':
          nextVerificationLevel = "general";
        default:
          nextVerificationLevel = 'mobile_id';
      }

      // rawData가 String인 경우 JSON 파싱
      Map<String, dynamic> dataMap;
      if (rawData is String) {
        try {
          dataMap = jsonDecode(rawData) as Map<String, dynamic>;
        } catch (e) {
          print('❌ JSON 파싱 실패: $e');
          return AuthResult.failure('인증 데이터 파싱에 실패했습니다.');
        }
      } else if (rawData is Map<String, dynamic>) {
        dataMap = rawData;
      } else {
        return AuthResult.failure('잘못된 인증 데이터 형식입니다.');
      }

      String verificationResult = dataMap['token'];

      return await recordIdentityVerification(
        userId: userId,
        nextVerificationLevel: nextVerificationLevel,
        isSuccess: success,
        verificationResult: verificationResult,
      );
    } catch (e) {
      print('❌ OmniOne 결과 처리 오류: $e');
      return AuthResult.failure('인증 결과 처리 중 오류가 발생했습니다: $e');
    }
  }

  /// OmniOne 토큰 파싱 (서버 API 호출)
  Future<AuthResult<Map<String, dynamic>>> _parseOmniOneTokenViaAPI(
    String token,
  ) async {
    try {
      print('🔍 서버를 통한 OmniOne 토큰 파싱 시작');

      final response = await _dioClient.post(
        '/oacx/api/v1.0/trans/token',
        data: {'token': token},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        print('✅ 서버 토큰 파싱 성공');
        return AuthResult.success(data);
      } else {
        print('❌ 서버 토큰 파싱 실패: ${response.statusCode}');
        return AuthResult.failure('토큰 파싱 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 서버 토큰 파싱 오류: $e');
      return AuthResult.failure('토큰 파싱 중 오류 발생');
    }
  }

  /// authType에서 provider 추출
  String _extractProviderFromAuthType(String authType) {
    switch (authType) {
      case 'simple':
        return 'comdl_v1.5';
      case 'mobile_id':
        return 'coidentitydocument_v1.5';
      default:
        return 'unknown';
    }
  }

  /// JWT 토큰의 페이로드 디코딩
  Map<String, dynamic>? _decodeJWTPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('❌ 잘못된 JWT 형식');
        return null;
      }

      // Base64 디코딩
      String payload = parts[1];

      // Base64 패딩 추가
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      // Base64 디코딩 및 JSON 파싱
      final decodedBytes = base64Decode(payload);
      final decodedString = utf8.decode(decodedBytes);
      final decodedJson = jsonDecode(decodedString) as Map<String, dynamic>;

      print('✅ JWT 페이로드 디코딩 성공');
      return decodedJson;
    } catch (e) {
      print('❌ JWT 디코딩 오류: $e');
      return null;
    }
  }

  /// 인증 방법 결정
  String _getVerificationMethod(String authType, String? provider) {
    if (provider != null) {
      // provider 기반 우선 판단
      switch (provider.toLowerCase()) {
        case 'comdl':
        case 'comdl_v1.5':
          return 'omni_mobile_license'; // 모바일 운전면허증
        case 'coidentitydocument':
        case 'coidentitydocument_v1.5':
          return 'mobile_id'; // 모바일 신분증
        case 'coresidence':
        case 'coresidence_v1.5':
          return 'omni_residence_card'; // 거주증
        case 'cokakao':
          return 'cokakao'; // 카카오 간편인증
        default:
          return 'omni_${provider}';
      }
    }

    // authType 기반 fallback
    switch (authType) {
      case 'simple':
        return 'omni_simple';
      case 'mobile_id':
        return 'mobile_id';
      case 'mobile_license':
        return 'omni_mobile_license';
      default:
        return 'omni_unknown';
    }
  }

  /// 전화번호 포맷 정리
  String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    // 숫자만 추출
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly;
  }

  /// 생년월일 포맷 정리
  String _formatBirthday(String birthday) {
    if (birthday.isEmpty) return '';
    // 숫자만 추출
    final digitsOnly = birthday.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly;
  }

  /// 성별 추정 (생년월일 마지막 자리 또는 기본값)
  String _determineSex(String birthday) {
    if (birthday.isEmpty) return '';

    // 생년월일이 8자리인 경우 (YYYYMMDD)
    if (birthday.length == 8) {
      // 한국 주민등록번호 규칙 적용 불가 (뒷자리가 없음)
      // 기본값 반환
      return '';
    }

    return ''; // 기본값
  }
}
