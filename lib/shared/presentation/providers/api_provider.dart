import 'package:flutter/foundation.dart';
import '../../data/services/api_service.dart';
import '../../../features/contents/data/performance_models.dart';
import '../../../features/auth/data/auth_service.dart';
import '../../../core/network/dio_client.dart';

/// API 서비스를 앱 전체에서 공유하기 위한 Provider
class ApiProvider extends ChangeNotifier {
  late final ApiService _apiService;
  late final AuthService _authService;
  late final DioClient _dioClient; // ✅ DioClient 직접 관리

  // 로딩 상태 관리
  bool _isLoading = false;
  String? _errorMessage;

  // 캐시된 데이터
  List<PerformanceHotItem>? _cachedHotPerformances;
  List<PerformanceAvailableItem>? _cachedAvailablePerformances;
  DateTime? _lastDataLoadTime;

  /// ✅ 생성자 - DioClient 공유
  ApiProvider() {
    _dioClient = DioClient(); // DioClient 하나만 생성
    _apiService = ApiService.withCustomClient(_dioClient); // 같은 DioClient 사용
    _authService = AuthService(_dioClient); // 같은 DioClient 사용
    _initializeProvider();
  }

  /// Getter들
  ApiService get apiService => _apiService;
  AuthService get authService => _authService;
  DioClient get dioClient => _dioClient; // ✅ DioClient getter 추가
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      print('🚀 ApiProvider 초기화 시작');

      // 네트워크 연결 확인
      final isConnected = await _apiService.checkConnection();
      if (!isConnected) {
        _setError('네트워크 연결을 확인해주세요.');
        return;
      }

      print('✅ ApiProvider 초기화 완료');
    } catch (e) {
      print('❌ ApiProvider 초기화 실패: $e');
      _setError('앱 초기화 중 오류가 발생했습니다.');
    }
  }

  /// ✅ 토큰 상태 디버그 (개발용)
  Future<void> debugTokens() async {
    await _dioClient.debugTokenStatus();
  }

  /// ✅ 강제 로그아웃 (토큰 만료 시)
  Future<void> forceLogout() async {
    try {
      print('🚨 강제 로그아웃 실행 - 토큰 만료');
      await _dioClient.clearTokens();

      // ⚠️ 임시: Refresh API 없음으로 인한 로그아웃 안내
      _setError('로그인이 만료되었습니다.\n다시 로그인해주세요.');

      notifyListeners();
    } catch (e) {
      print('❌ 강제 로그아웃 오류: $e');
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

      // 401 오류인 경우 강제 로그아웃
      if (e.toString().contains('401') || e.toString().contains('인증')) {
        await forceLogout();
      } else {
        _setError('공연 정보를 불러올 수 없습니다. 다시 시도해주세요.');
      }
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

      // 401 오류인 경우 강제 로그아웃
      if (e.toString().contains('401') || e.toString().contains('인증')) {
        await forceLogout();
      } else {
        _setError('재연결 중 오류가 발생했습니다.');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// 캐시 데이터 강제 새로고침
  Future<void> refreshData() async {
    await loadDashboardData(forceRefresh: true);
  }

  /// 캐시 데이터 클리어
  void clearCache() {
    _cachedHotPerformances = null;
    _cachedAvailablePerformances = null;
    _lastDataLoadTime = null;
    print('🗑️ 캐시 데이터 클리어 완료');
    notifyListeners();
  }

  /// API 서비스 상태 진단
  Future<Map<String, bool>> diagnoseServices() async {
    try {
      _setLoading(true);
      clearError();

      final results = await _apiService.diagnoseServices();
      print('🔍 API 서비스 진단 완료: $results');
      return results;
    } catch (e) {
      print('❌ API 서비스 진단 실패: $e');

      // 401 오류인 경우 강제 로그아웃
      if (e.toString().contains('401') || e.toString().contains('인증')) {
        await forceLogout();
      } else {
        _setError('서비스 상태 확인 중 오류가 발생했습니다.');
      }
      return {};
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ Provider 리소스 정리
  @override
  void dispose() {
    print('🗑️ ApiProvider dispose 시작');
    _apiService.dispose();
    // DioClient는 여기서 명시적으로 dispose하지 않음 (Dio가 자동 관리)
    super.dispose();
    print('✅ ApiProvider dispose 완료');
  }
}
