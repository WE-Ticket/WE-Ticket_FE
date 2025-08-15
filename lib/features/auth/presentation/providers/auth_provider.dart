import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_ticket/core/network/dio_client.dart';
import 'package:we_ticket/features/auth/data/auth_service.dart';
import 'package:we_ticket/features/auth/data/user_models.dart';

class AuthProvider extends ChangeNotifier {
  final DioClient _dioClient; // ✅ DioClient 참조 추가

  bool _isLoggedIn = false;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // 인증 처리 관련 상태 추가
  bool _isProcessingAuth = false;
  String? _currentAuthType;

  // ✅ 생성자에서 DioClient 주입받기
  AuthProvider(this._dioClient);

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isProcessingAuth => _isProcessingAuth;
  String? get currentAuthType => _currentAuthType;

  static const Map<String, String> _authLevelNames = {
    'none': '미인증',
    'general': '일반 인증',
    'mobile_id': '모바일 신분증 인증',
    'mobile_id_totally': '안전 인증',
  };

  /// ✅ 앱 시작시 로그인 상태 확인 - 개선된 로직
  Future<void> checkAuthStatus() async {
    try {
      print('🔍 로그인 상태 확인 시작');

      // DioClient 토큰 상태 먼저 확인
      final hasValidTokens = await _dioClient.hasValidTokens();

      if (!hasValidTokens) {
        print('⚠️ 유효한 토큰 없음 - 로그아웃 상태');
        await _clearAllUserData();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (isLoggedIn) {
        final userId = prefs.getInt('user_id');
        final loginId = prefs.getString('login_id');
        final userName = prefs.getString('user_name');
        final userAuthLevel = prefs.getString('user_auth_level');

        if (userId != null &&
            loginId != null &&
            userName != null &&
            userAuthLevel != null) {
          _user = UserModel(
            userId: userId,
            loginId: loginId,
            userName: userName,
            userAuthLevel: userAuthLevel,
          );
          _isLoggedIn = true;
          print('✅ 저장된 로그인 상태 복원: $userName');
          notifyListeners();
        } else {
          print('⚠️ 불완전한 사용자 데이터 - 로그아웃 처리');
          await _clearAllUserData();
        }
      }
    } catch (e) {
      print('❌ 로그인 상태 확인 오류: $e');
      await _clearAllUserData();
    }
  }

  /// ✅ 로그인 - 토큰 설정 강화
  Future<bool> login({
    required String loginId,
    required String password,
    required AuthService authService,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 로그인 시작: $loginId');

      // 기존 토큰 완전 삭제
      await _dioClient.clearTokens();

      final result = await authService.login(
        loginId: loginId,
        password: password,
      );

      if (result.isSuccess && result.data != null) {
        final loginResponse = result.data!;
        final user = loginResponse.toUserModel();

        print('✅ 로그인 API 성공');

        // 토큰을 DioClient에 설정
        await _dioClient.setAccessToken(loginResponse.accessToken);
        await _dioClient.setRefreshToken(loginResponse.refreshToken);

        // 사용자 정보 저장
        await _setLoggedInUser(user, token: loginResponse.accessToken);

        // 토큰 상태 디버그
        await _dioClient.debugTokenStatus();

        return true;
      } else {
        _setError(result.errorMessage!);
        print('❌ 로그인 실패: ${result.errorMessage}');
        return false;
      }
    } catch (e) {
      print('❌ 로그인 처리 오류: $e');
      _setError('로그인 중 오류가 발생했습니다');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 회원가입
  Future<bool> signup({
    required String fullName,
    required String loginId,
    required String phoneNumber,
    required String password,
    required bool agreeTerms,
    required bool agreePrivacy,
    required AuthService authService,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await authService.signup(
        fullName: fullName,
        loginId: loginId,
        phoneNumber: phoneNumber,
        password: password,
        agreeTerms: agreeTerms,
        agreePrivacy: agreePrivacy,
      );

      if (result.isSuccess) {
        print('✅ 회원가입 성공');
        return true;
      } else {
        _setError(result.errorMessage!);
        print('❌ 회원가입 실패: ${result.errorMessage}');
        return false;
      }
    } catch (e) {
      print('❌ 회원가입 처리 오류: $e');
      _setError('회원가입 중 오류가 발생했습니다');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// OmniOne CX 인증 결과 처리 (NEW)
  Future<bool> processOmniOneAuthentication({
    required Map<String, dynamic> omniOneResult,
    required AuthService authService,
  }) async {
    if (_user == null) {
      _setError('로그인이 필요합니다');
      return false;
    }

    _setAuthProcessing(true, omniOneResult['authType']);
    _clearError();

    try {
      print('🔐 OmniOne 인증 결과 처리 시작');

      // 1. 서버에 인증 결과 기록
      final recordResult = await authService.processOmniOneResult(
        userId: _user!.userId,
        omniOneResult: omniOneResult,
      );

      if (recordResult.isSuccess) {
        // 2. 새로운 인증 레벨이 있다면 업데이트
        final newLevel = recordResult.data?.newVerificationLevel;
        if (newLevel != null) {
          await updateAuthLevel(newLevel);
        }

        // 3. 현재 사용자의 최신 인증 레벨 재조회
        await refreshUserAuthLevel(authService);

        print('✅ OmniOne 인증 처리 완료');
        return true;
      } else {
        _setError(recordResult.errorMessage!);
        print('❌ OmniOne 인증 처리 실패: ${recordResult.errorMessage}');
        return false;
      }
    } catch (e) {
      print('❌ OmniOne 인증 처리 오류: $e');
      _setError('인증 처리 중 오류가 발생했습니다');
      return false;
    } finally {
      _setAuthProcessing(false, null);
    }
  }

  /// 사용자 인증 레벨 새로고침 (NEW)
  Future<void> refreshUserAuthLevel(AuthService authService) async {
    if (_user == null) return;

    try {
      print('🔄 사용자 인증 레벨 새로고침');

      final result = await authService.loadUserAuthLevel(_user!.userId);

      if (result.isSuccess && result.data != null) {
        final authLevel = result.data!['auth_level'] as String?;
        if (authLevel != null) {
          await updateAuthLevel(authLevel);
          print('✅ 인증 레벨 새로고침 완료: $authLevel');
        }
      }
    } catch (e) {
      print('❌ 인증 레벨 새로고침 오류: $e');
    }
  }

  /// 간편 인증 처리 (NEW)
  Future<bool> processSimpleAuthentication({
    required Map<String, dynamic> authResult,
    required AuthService authService,
  }) async {
    return await processOmniOneAuthentication(
      omniOneResult: {
        'authType': 'simple',
        'success': authResult['success'] ?? false,
        'data': authResult['data'] ?? {},
      },
      authService: authService,
    );
  }

  /// 모바일 신분증 인증 처리 (NEW)
  Future<bool> processMobileIdAuthentication({
    required Map<String, dynamic> authResult,
    required AuthService authService,
  }) async {
    return await processOmniOneAuthentication(
      omniOneResult: {
        'authType': 'mobile_id',
        'success': authResult['success'] ?? false,
        'data': authResult['data'] ?? {},
      },
      authService: authService,
    );
  }

  /// API 로그인 성공 후 상태 업데이트
  Future<void> updateFromApiLogin(UserModel user, {String? token}) async {
    await _setLoggedInUser(user, token: token);
  }

  /// ✅ 로그아웃 - 완전한 정리
  Future<void> logout() async {
    try {
      print('🚪 로그아웃 시작');

      // 1. DioClient 토큰 완전 삭제
      await _dioClient.clearTokens();

      // 2. 모든 사용자 데이터 삭제
      await _clearAllUserData();

      print('✅ 로그아웃 완료');
    } catch (e) {
      print('❌ 로그아웃 오류: $e');
      _setError('로그아웃 중 오류가 발생했습니다');
    }
  }

  // Private methods

  /// ✅ 모든 사용자 데이터 완전 삭제
  Future<void> _clearAllUserData() async {
    try {
      // 메모리 상태 초기화
      _user = null;
      _isLoggedIn = false;
      _clearError();
      _setAuthProcessing(false, null);

      // SharedPreferences 완전 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('🗑️ 모든 사용자 데이터 삭제 완료');
      notifyListeners();
    } catch (e) {
      print('❌ 사용자 데이터 삭제 오류: $e');
      rethrow;
    }
  }

  /// ✅ 로그인 사용자 설정 및 저장 - 개선된 로직
  Future<void> _setLoggedInUser(UserModel user, {String? token}) async {
    try {
      _user = user;
      _isLoggedIn = true;

      // SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setInt('user_id', user.userId);
      await prefs.setString('login_id', user.loginId);
      await prefs.setString('user_name', user.userName);
      await prefs.setString('user_auth_level', user.userAuthLevel);

      // 토큰이 제공된 경우 저장 (하지만 DioClient에서 이미 저장했으므로 중복 확인)
      if (token != null) {
        final storedToken = prefs.getString('access_token');
        if (storedToken != token) {
          await prefs.setString('access_token', token);
          print('⚠️ 토큰 불일치 감지 - 동기화 완료');
        }
      }

      print('💾 사용자 정보 저장 완료: ${user.userName}');
      notifyListeners();
    } catch (e) {
      print('❌ 사용자 정보 저장 오류: $e');
      rethrow;
    }
  }

  /// 사용자 인증 레벨 업데이트
  Future<void> updateAuthLevel(String? newAuthLevel) async {
    if (_user == null || newAuthLevel == null) return;

    try {
      // 현재 사용자 정보에서 인증 레벨만 업데이트
      _user = UserModel(
        userId: _user!.userId,
        loginId: _user!.loginId,
        userName: _user!.userName,
        userAuthLevel: newAuthLevel,
      );

      // SharedPreferences에도 업데이트
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_auth_level', newAuthLevel);

      print('✅ 인증 레벨 업데이트: $newAuthLevel');
      notifyListeners();
    } catch (e) {
      print('❌ 인증 레벨 업데이트 오류: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 인증 처리 상태 설정 (NEW)
  void _setAuthProcessing(bool processing, String? authType) {
    _isProcessingAuth = processing;
    _currentAuthType = authType;
    notifyListeners();
  }

  // 편의용 getter들
  String? get userId => _user?.userId.toString();
  String? get userName => _user?.userName;
  bool get hasValidSession => _isLoggedIn && _user != null;
  int? get currentUserId => _user?.userId;
  String? get currentUserName => _user?.userName;
  String? get currentLoginId => _user?.loginId;
  String? get currentUserAuthLevel => _user?.userAuthLevel;

  /// 권한 레벨 한국어 이름 반환
  String get currentUserAuthLevelName {
    if (_user?.userAuthLevel == null) return '미로그인';
    return _authLevelNames[_user!.userAuthLevel] ?? '알 수 없음';
  }

  static String getAuthLevelName(String authLevel) {
    return _authLevelNames[authLevel] ?? '알 수 없음';
  }

  /// 에러 메시지 지우기
  void clearError() {
    _clearError();
  }

  /// 인증 가능 여부 확인 (NEW)
  bool canUpgradeAuth() {
    if (_user == null) return false;
    return _user!.userAuthLevel != 'mobile_id_totally';
  }

  /// 다음 인증 단계 반환 (NEW)
  String? getNextAuthStep() {
    if (_user == null) return null;

    switch (_user!.userAuthLevel) {
      case 'none':
        return 'simple'; // 간편 인증 또는 모바일 신분증
      case 'general':
        return 'mobile_id'; // 모바일 신분증
      case 'mobile_id':
        return 'totally'; // 안전 인증
      default:
        return null;
    }
  }

  int get currentAuthLevelStep {
    if (_user == null) return 0;

    switch (_user!.userAuthLevel) {
      case 'none':
        return 0;
      case 'general':
        return 1;
      case 'mobile_id':
        return 2;
      case 'mobile_id_totally':
        return 3;
      default:
        return 0;
    }
  }
}
