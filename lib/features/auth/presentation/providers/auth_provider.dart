import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserModel? _user;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // FIXME 더미 사용자 데이터 (호환성을 위해 유지)
  static const Map<String, String> _dummyUsers = {
    'testuser': 'password123',
    'weticket': '1234',
    'demo': 'demo',
  };

  /// 앱 시작 시 저장된 로그인 상태 확인
  Future<void> checkAuthStatus() async {
    try {
      // //FIXME 무조건 지워야!!! (로그인 API 복구되면)
      // _user = UserModel(id: "1", name: "테스트 사용자");
      // _isLoggedIn = true;
      // print('✅ 강제 로그인 상태 설정: 사용자 ID 1');
      // notifyListeners();
      // return; // 여기서 종료해서 아래 코드 실행 안 함

      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final savedId = prefs.getString('user_id');
      final savedName = prefs.getString('user_name');
      final loginType =
          prefs.getString('login_type') ?? 'dummy'; // API 또는 더미 로그인 구분

      if (isLoggedIn && savedId != null && savedName != null) {
        _user = UserModel(id: savedId, name: savedName);
        _isLoggedIn = true;
        print('✅ 저장된 로그인 상태 복원: $savedId ($loginType)');
        notifyListeners();
      }
    } catch (e) {
      print('❌ 로그인 상태 확인 오류: $e');
    }
  }

  /// API 로그인 성공 후 상태 업데이트
  Future<void> updateFromApiLogin({
    required String userId,
    required String userName,
    String? token,
  }) async {
    try {
      _user = UserModel(id: userId, name: userName);
      _isLoggedIn = true;

      // API 로그인 정보 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_id', userId);
      await prefs.setString('user_name', userName);
      await prefs.setString('login_type', 'api');

      if (token != null) {
        await prefs.setString('auth_token', token);
      }

      print('✅ API 로그인 상태 업데이트 완료: $userId');
      notifyListeners();
    } catch (e) {
      print('❌ API 로그인 상태 업데이트 오류: $e');
    }
  }

  /// 더미 로그인 (개발용 - 호환성을 위해 유지)
  Future<bool> login(String id, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 로딩 시뮬레이션
      await Future.delayed(Duration(milliseconds: 500));

      // 더미 사용자 확인
      if (_dummyUsers.containsKey(id) && _dummyUsers[id] == password) {
        _user = UserModel(id: id, name: _getNameFromId(id));
        _isLoggedIn = true;

        // 더미 로그인 상태 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_id', id);
        await prefs.setString('user_name', _user!.name);
        await prefs.setString('login_type', 'dummy');

        _isLoading = false;
        print('✅ 더미 로그인 성공: $id');
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        print('❌ 더미 로그인 실패: $id');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      print('❌ 더미 로그인 오류: $e');
      notifyListeners();
      return false;
    }
  }

  /// 직접 로그인 상태 설정 (API 로그인 후 호출용)
  Future<void> setLoggedIn({
    required String userId,
    required String userName,
    String? token,
    bool saveToStorage = true,
  }) async {
    try {
      _user = UserModel(id: userId, name: userName);
      _isLoggedIn = true;

      if (saveToStorage) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_id', userId);
        await prefs.setString('user_name', userName);
        await prefs.setString('login_type', 'api');

        if (token != null) {
          await prefs.setString('auth_token', token);
        }
      }

      print('✅ 로그인 상태 설정 완료: $userId');
      notifyListeners();
    } catch (e) {
      print('❌ 로그인 상태 설정 오류: $e');
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      _user = null;
      _isLoggedIn = false;

      // 저장된 상태 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('✅ 로그아웃 완료');
      notifyListeners();
    } catch (e) {
      print('❌ 로그아웃 오류: $e');
    }
  }

  /// 토큰 가져오기
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('❌ 토큰 조회 오류: $e');
      return null;
    }
  }

  /// 로그인 타입 확인
  Future<String> getLoginType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('login_type') ?? 'dummy';
    } catch (e) {
      print('❌ 로그인 타입 조회 오류: $e');
      return 'dummy';
    }
  }

  /// 사용자 ID만 가져오기
  String? get userId => _user?.id;

  /// 사용자 이름만 가져오기
  String? get userName => _user?.name;

  /// 로그인 여부 간단 확인
  bool get hasValidSession => _isLoggedIn && _user != null;

  // FIXME 더미 데이터 변환 함수 (호환성을 위해 유지)
  String _getNameFromId(String id) {
    switch (id) {
      case 'testuser':
        return '테스트 사용자';
      case 'weticket':
        return 'WE-Ticket 사용자';
      case 'demo':
        return '데모 사용자';
      default:
        return '${id} 님';
    }
  }

  /// 더미 사용자 목록 (디버그용)
  Map<String, String> get dummyUsers => _dummyUsers;

  /// 디버그 정보 출력
  void printDebugInfo() {
    print('=== AuthProvider Debug Info ===');
    print('isLoggedIn: $_isLoggedIn');
    print('user: $_user');
    print('isLoading: $_isLoading');
    print('================================');
  }
}

/// 사용자 모델
class UserModel {
  final String id;
  final String name;

  UserModel({required this.id, required this.name});

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name)';
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  /// JSON에서 생성
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'] ?? '', name: json['name'] ?? '');
  }

  /// 복사본 생성
  UserModel copyWith({String? id, String? name}) {
    return UserModel(id: id ?? this.id, name: name ?? this.name);
  }
}
