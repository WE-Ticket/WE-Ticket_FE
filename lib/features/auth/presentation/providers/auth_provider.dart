import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_ticket/features/auth/data/auth_service.dart';
import 'package:we_ticket/features/auth/data/user_models.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const Map<String, String> _authLevelNames = {
    'none': '미인증',
    'general': '일반 인증',
    'mobile_id': '모바일 신분증 인증',
    'mobile_id_totally': '안전 인증',
  };

  /// 앱 시작시 로그인 상태 확인
  Future<void> checkAuthStatus() async {
    try {
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
        }
      }
    } catch (e) {
      print('❌ 로그인 상태 확인 오류: $e');
    }
  }

  /// 로그인
  Future<bool> login({
    required String loginId,
    required String password,
    required AuthService authService,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await authService.login(
        loginId: loginId,
        password: password,
      );

      if (result.isSuccess && result.data != null) {
        final user = result.data!.toUserModel();
        await _setLoggedInUser(user);
        print('✅ 로그인 성공: ${user.userName}');
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

  /// API 로그인 성공 후 상태 업데이트
  Future<void> updateFromApiLogin(UserModel user, {String? token}) async {
    await _setLoggedInUser(user, token: token);
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      _user = null;
      _isLoggedIn = false;
      _clearError();

      // 저장된 상태 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('✅ 로그아웃 완료');
      notifyListeners();
    } catch (e) {
      print('❌ 로그아웃 오류: $e');
      _setError('로그아웃 중 오류가 발생했습니다');
    }
  }

  // Private methods

  /// 로그인 사용자 설정 및 저장
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

      if (token != null) {
        await prefs.setString('auth_token', token);
      }

      notifyListeners();
    } catch (e) {
      print('❌ 사용자 정보 저장 오류: $e');
      rethrow;
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
}
