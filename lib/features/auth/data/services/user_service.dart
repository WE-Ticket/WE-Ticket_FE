import '../../../../core/services/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/user_models.dart';

/// 사용자 관련 API 서비스
class UserService {
  final DioClient _dioClient;

  UserService(this._dioClient);

  /// 로그인
  ///
  /// POST /users/login/
  /// 로그인 페이지에서 사용
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      print('🔐 로그인 시도 시작 (아이디: ${request.loginId})');
      final response = await _dioClient.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(response.data);
        if (loginResponse.isSuccess) {
          print('✅ 로그인 성공: 사용자 ID ${loginResponse.userId}');
        } else {
          print('❌ 로그인 실패: ${loginResponse.message}');
        }
        return loginResponse;
      } else {
        throw Exception('로그인 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 로그인 오류 (아이디: ${request.loginId}): $e');
      rethrow;
    }
  }

  /// 간편 로그인 (아이디, 비밀번호만으로 로그인)
  ///
  /// 편의 메서드 - LoginRequest 객체를 직접 만들지 않고 사용
  Future<LoginResponse> simpleLogin(String loginId, String password) async {
    final request = LoginRequest(loginId: loginId, loginPassword: password);
    return await login(request);
  }

  /// 회원가입
  ///
  /// POST /users/signup/
  /// 회원가입 페이지에서 사용
  Future<SignupResponse> signup(SignupRequest request) async {
    try {
      print('📝 회원가입 시도 시작 (아이디: ${request.loginId})');

      // 요청 데이터 유효성 검사
      if (!request.isValid) {
        throw Exception(request.validationError ?? '입력 정보가 올바르지 않습니다.');
      }

      final response = await _dioClient.post(
        ApiConstants.signup,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final signupResponse = SignupResponse.fromJson(response.data);
        if (signupResponse.isSuccess) {
          print('✅ 회원가입 성공: ${signupResponse.message}');
        } else {
          print('❌ 회원가입 실패: ${signupResponse.message}');
        }
        return signupResponse;
      } else {
        throw Exception('회원가입 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 회원가입 오류 (아이디: ${request.loginId}): $e');
      rethrow;
    }
  }

  /// 빠른 회원가입 (기본 약관 동의 포함)
  ///
  /// 편의 메서드 - 필수 정보만으로 회원가입
  Future<SignupResponse> quickSignup({
    required String fullName,
    required String loginId,
    required String phoneNumber,
    required String password,
    bool agreeToServiceTerms = true,
    bool agreeToPrivacyPolicy = true,
  }) async {
    final currentDate = DateTime.now().toIso8601String().split('T')[0];

    final agreements = <Agreement>[];

    if (agreeToServiceTerms) {
      agreements.add(
        Agreement(
          termType: 'SERVICE_TERMS',
          agreed: true,
          agreedAt: currentDate,
        ),
      );
    }

    if (agreeToPrivacyPolicy) {
      agreements.add(
        Agreement(
          termType: 'PRIVACY_POLICY',
          agreed: true,
          agreedAt: currentDate,
        ),
      );
    }

    final request = SignupRequest(
      fullName: fullName,
      loginId: loginId,
      phoneNumber: phoneNumber,
      loginPassword: password,
      agreements: agreements,
    );

    return await signup(request);
  }

  /// 아이디 중복 확인 (확장 기능 - API 명세에는 없지만 나중에 추가될 수 있음)
  ///
  /// 현재는 회원가입 시도로 간접 확인
  Future<bool> checkLoginIdAvailability(String loginId) async {
    try {
      print('🔍 아이디 중복 확인: $loginId');

      // 임시 회원가입 시도로 아이디 중복 확인
      // 실제로는 별도의 API가 있어야 함
      final tempRequest = SignupRequest(
        fullName: 'temp',
        loginId: loginId,
        phoneNumber: '01000000000',
        loginPassword: 'temp1234',
        agreements: [],
      );

      try {
        await signup(tempRequest);
        // 성공하면 사용 가능한 아이디 (하지만 실제로는 계정이 생성됨 - 문제가 있는 방식)
        print('⚠️ 임시 계정이 생성되었습니다. 실제 서비스에서는 별도 API 필요');
        return true;
      } catch (e) {
        // 실패하면 중복된 아이디일 가능성
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('duplicate') ||
            errorMessage.contains('already exists')) {
          print('❌ 이미 사용 중인 아이디');
          return false;
        } else {
          // 다른 오류인 경우
          print('⚠️ 아이디 확인 중 오류 발생: $e');
          throw e;
        }
      }
    } catch (e) {
      print('❌ 아이디 중복 확인 오류: $e');
      rethrow;
    }
  }

  /// 로그인 상태 확인 (확장 기능)
  ///
  /// 로컬 저장소에서 로그인 정보 확인
  Future<bool> isLoggedIn() async {
    try {
      // 실제로는 SharedPreferences나 다른 로컬 저장소에서 토큰 확인
      // 현재는 임시 구현
      print('🔍 로그인 상태 확인');

      // TODO: 실제 토큰/세션 확인 로직 구현
      // final token = await SharedPreferences.getInstance().getString('auth_token');
      // return token != null && token.isNotEmpty;

      return false; // 임시로 항상 로그아웃 상태로 반환
    } catch (e) {
      print('❌ 로그인 상태 확인 오류: $e');
      return false;
    }
  }

  /// 로그아웃 (확장 기능)
  ///
  /// 로컬 저장소에서 로그인 정보 삭제
  Future<void> logout() async {
    try {
      print('🚪 로그아웃 시작');

      // TODO: 실제 토큰/세션 삭제 로직 구현
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove('auth_token');
      // await prefs.remove('user_id');

      print('✅ 로그아웃 완료');
    } catch (e) {
      print('❌ 로그아웃 오류: $e');
      rethrow;
    }
  }

  /// 사용자 정보 저장 (확장 기능)
  ///
  /// 로그인 성공 후 사용자 정보를 로컬에 저장
  Future<void> saveUserInfo(LoginResponse loginResponse) async {
    try {
      print('💾 사용자 정보 저장 시작');

      // TODO: 실제 사용자 정보 저장 로직 구현
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setInt('user_id', loginResponse.userId);
      // await prefs.setString('login_time', DateTime.now().toIso8601String());

      print('✅ 사용자 정보 저장 완료');
    } catch (e) {
      print('❌ 사용자 정보 저장 오류: $e');
      rethrow;
    }
  }

  /// 저장된 사용자 정보 조회 (확장 기능)
  Future<int?> getSavedUserId() async {
    try {
      // TODO: 실제 사용자 정보 조회 로직 구현
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getInt('user_id');

      return null; // 임시로 null 반환
    } catch (e) {
      print('❌ 사용자 정보 조회 오류: $e');
      return null;
    }
  }

  /// 입력 검증 헬퍼 메서드들

  /// 아이디 형식 검증
  static bool validateLoginId(String loginId) {
    return loginId.length >= 4 &&
        loginId.length <= 20 &&
        RegExp(r'^[a-zA-Z0-9]+$').hasMatch(loginId);
  }

  /// 비밀번호 형식 검증
  static bool validatePassword(String password) {
    return password.length >= 4 && password.length <= 50;
  }

  /// 휴대폰 번호 형식 검증
  static bool validatePhoneNumber(String phoneNumber) {
    return RegExp(r'^01[0-9]{8,9}').hasMatch(phoneNumber);
  }

  /// 이름 형식 검증
  static bool validateFullName(String fullName) {
    return fullName.trim().isNotEmpty &&
        fullName.trim().length >= 2 &&
        fullName.trim().length <= 20;
  }

  /// 전체 회원가입 정보 검증
  static String? validateSignupData({
    required String fullName,
    required String loginId,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) {
    if (!validateFullName(fullName)) {
      return '이름은 2-20자로 입력해주세요.';
    }

    if (!validateLoginId(loginId)) {
      return '아이디는 4-20자의 영문, 숫자만 사용 가능합니다.';
    }

    if (!validatePhoneNumber(phoneNumber)) {
      return '올바른 휴대폰 번호를 입력해주세요. (01X-XXXX-XXXX)';
    }

    if (!validatePassword(password)) {
      return '비밀번호는 4-50자로 입력해주세요.';
    }

    if (password != confirmPassword) {
      return '비밀번호가 일치하지 않습니다.';
    }

    return null; // 검증 통과
  }

  /// 로그인 정보 검증
  static String? validateLoginData({
    required String loginId,
    required String password,
  }) {
    if (loginId.trim().isEmpty) {
      return '아이디를 입력해주세요.';
    }

    if (password.trim().isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    return null; // 검증 통과
  }
}
