import 'package:dio/dio.dart';
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
        loginPassword: password,
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
