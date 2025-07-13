import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/performance_models.dart';
import '../models/user_models.dart';

/// API 서비스를 앱 전체에서 공유하기 위한 Provider
///
/// ChangeNotifier를 상속받아 상태 변화를 UI에 알릴 수 있음.
/// Provider 패키지와 함께 사용하면 의존성 주입과 상태 관리가 편해진다고...
class ApiProvider extends ChangeNotifier {
  late final ApiService _apiService;

  // 로딩 상태 관리
  bool _isLoading = false;
  String? _errorMessage;

  // 캐시된 데이터
  List<PerformanceHotItem>? _cachedHotPerformances;
  List<PerformanceAvailableItem>? _cachedAvailablePerformances;
  DateTime? _lastDataLoadTime;

  // 사용자 상태
  bool _isLoggedIn = false;
  int? _currentUserId;

  /// 생성자
  ApiProvider() {
    _apiService = ApiService.create();
    _initializeProvider();
  }

  /// Getter들
  ApiService get apiService => _apiService;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  int? get currentUserId => _currentUserId;

  List<PerformanceHotItem>? get cachedHotPerformances => _cachedHotPerformances;
  List<PerformanceAvailableItem>? get cachedAvailablePerformances =>
      _cachedAvailablePerformances;

  /// 캐시된 데이터가 유효한지 확인 (5분 이내)
  bool get isCacheValid {
    if (_lastDataLoadTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastDataLoadTime!);
    return difference.inMinutes < 5;
  }

  /// Provider 초기화
  Future<void> _initializeProvider() async {
    try {
      print('ApiProvider 초기화 시작');

      // 네트워크 연결 확인
      final isConnected = await _apiService.checkConnection();
      if (!isConnected) {
        _setError('네트워크 연결을 확인해주세요.');
        return;
      }

      // 로그인 상태 확인
      _isLoggedIn = await _apiService.user.isLoggedIn();
      if (_isLoggedIn) {
        _currentUserId = await _apiService.user.getSavedUserId();
      }

      print('✅ ApiProvider 초기화 완료');
    } catch (e) {
      print('❌ ApiProvider 초기화 실패: $e');
      _setError('앱 초기화 중 오류가 발생했습니다.');
    }
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 에러 메시지 설정
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 에러 메시지 지우기
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 대시보드 데이터 로드 (캐시 고려)
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    try {
      // 캐시가 유효하고 강제 새로고침이 아니라면 스킵
      if (!forceRefresh &&
          isCacheValid &&
          _cachedHotPerformances != null &&
          _cachedAvailablePerformances != null) {
        print('📦 캐시된 대시보드 데이터 사용');
        return;
      }

      _setLoading(true);
      clearError();

      print('🔄 대시보드 데이터 새로 로드');

      final dashboardData = await _apiService.loadDashboardData();

      _cachedHotPerformances = dashboardData['hotPerformances'];
      _cachedAvailablePerformances = dashboardData['availablePerformances'];
      _lastDataLoadTime = DateTime.now();

      print('✅ 대시보드 데이터 로드 완료');
    } catch (e) {
      print('❌ 대시보드 데이터 로드 실패: $e');
      _setError('공연 정보를 불러올 수 없습니다. 다시 시도해주세요.');
    } finally {
      _setLoading(false);
    }
  }

  /// 로그인 처리
  Future<bool> login(String loginId, String password) async {
    try {
      _setLoading(true);
      clearError();

      print('🔐 로그인 시도: $loginId');

      final response = await _apiService.user.simpleLogin(loginId, password);

      if (response.isSuccess) {
        _isLoggedIn = true;
        _currentUserId = response.userId;

        // 로그인 정보 저장
        await _apiService.user.saveUserInfo(response);

        // 로그인 후 사용자 데이터 로드
        await _apiService.loadUserInitialData(response.userId);

        print('✅ 로그인 성공');
        return true;
      } else {
        _setError(response.message);
        print('❌ 로그인 실패: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ 로그인 오류: $e');
      _setError('로그인 중 오류가 발생했습니다. 다시 시도해주세요.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 로그아웃 처리
  Future<void> logout() async {
    try {
      print('🚪 로그아웃 시작');

      await _apiService.user.logout();

      _isLoggedIn = false;
      _currentUserId = null;

      // 캐시된 사용자 데이터 클리어
      _cachedHotPerformances = null;
      _cachedAvailablePerformances = null;
      _lastDataLoadTime = null;

      notifyListeners();
      print('✅ 로그아웃 완료');
    } catch (e) {
      print('❌ 로그아웃 오류: $e');
      _setError('로그아웃 중 오류가 발생했습니다.');
    }
  }

  /// 회원가입 처리
  Future<bool> signup({
    required String fullName,
    required String loginId,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      _setLoading(true);
      clearError();

      print('📝 회원가입 시도: $loginId');

      final response = await _apiService.user.quickSignup(
        fullName: fullName,
        loginId: loginId,
        phoneNumber: phoneNumber,
        password: password,
      );

      if (response.isSuccess) {
        print('✅ 회원가입 성공');
        return true;
      } else {
        _setError(response.message);
        print('❌ 회원가입 실패: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ 회원가입 오류: $e');
      _setError('회원가입 중 오류가 발생했습니다. 다시 시도해주세요.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 네트워크 재연결 시도
  Future<void> reconnect() async {
    try {
      _setLoading(true);
      clearError();

      print('🔄 네트워크 재연결 시도');

      final isConnected = await _apiService.checkConnection();

      if (isConnected) {
        print('✅ 네트워크 재연결 성공');
        // 연결 성공 시 대시보드 데이터 새로 로드
        await loadDashboardData(forceRefresh: true);
      } else {
        _setError('네트워크 연결에 실패했습니다. 연결 상태를 확인해주세요.');
      }
    } catch (e) {
      print('❌ 네트워크 재연결 실패: $e');
      _setError('재연결 중 오류가 발생했습니다.');
    } finally {
      _setLoading(false);
    }
  }

  /// 캐시 데이터 강제 새로고침
  Future<void> refreshData() async {
    await loadDashboardData(forceRefresh: true);
  }

  /// Provider 리소스 정리
  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
