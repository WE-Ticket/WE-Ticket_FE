import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserModel? _user;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // FIXME 더미 사용자 데이터
  static const Map<String, String> _dummyUsers = {
    'testuser': 'password123',
    'weticket': '1234',
    'demo': 'demo',
  };

  /// 앱 시작 시 저장된 로그인 상태 확인
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final savedId = prefs.getString('user_id');
    final savedName = prefs.getString('user_name');

    if (isLoggedIn && savedId != null && savedName != null) {
      _user = UserModel(id: savedId, name: savedName);
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  /// 로그인
  Future<bool> login(String id, String password) async {
    _isLoading = true;
    notifyListeners();

    // 로딩 시뮬레이션
    await Future.delayed(Duration(seconds: 1));

    // 더미 사용자 확인
    if (_dummyUsers.containsKey(id) && _dummyUsers[id] == password) {
      _user = UserModel(id: id, name: _getNameFromId(id));
      _isLoggedIn = true;

      // 로그인 상태 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_id', id);
      await prefs.setString('user_name', _user!.name);

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    _user = null;
    _isLoggedIn = false;

    // 저장된 상태 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  // FIXME
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
}
