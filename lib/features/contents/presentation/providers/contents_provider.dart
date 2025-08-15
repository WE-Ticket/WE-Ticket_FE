import 'package:flutter/foundation.dart';
import '../../data/performance_service.dart';
import '../../data/performance_models.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/network/api_result.dart';

/// Contents/Performance 기능을 관리하는 Provider
/// 공연 목록, 상세 정보, 검색 등의 상태를 관리합니다.
class ContentsProvider extends ChangeNotifier {
  final PerformanceService _performanceService;

  // 상태 관리
  bool _isLoading = false;
  String? _errorMessage;

  // 공연 데이터
  List<PerformanceHotItem>? _hotPerformances;
  List<PerformanceAvailableItem>? _availablePerformances;
  PerformanceListResponse? _allPerformances;
  PerformanceDetail? _selectedPerformance;
  List<PerformanceListItem>? _filteredPerformances;

  // 캐시 관리
  DateTime? _lastDataLoadTime;
  String? _currentGenreFilter;
  int _currentPage = 1;

  ContentsProvider({
    required PerformanceService performanceService,
  }) : _performanceService = performanceService;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PerformanceHotItem>? get hotPerformances => _hotPerformances;
  List<PerformanceAvailableItem>? get availablePerformances => _availablePerformances;
  PerformanceListResponse? get allPerformances => _allPerformances;
  PerformanceDetail? get selectedPerformance => _selectedPerformance;
  List<PerformanceListItem>? get filteredPerformances => _filteredPerformances;
  String? get currentGenreFilter => _currentGenreFilter;
  int get currentPage => _currentPage;

  /// 캐시된 데이터가 유효한지 확인 (5분 이내)
  bool get isCacheValid {
    if (_lastDataLoadTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastDataLoadTime!);
    return difference.inMinutes < 5;
  }

  /// 대시보드용 데이터 로드 (HOT + Available)
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    if (!forceRefresh && isCacheValid && _hotPerformances != null && _availablePerformances != null) {
      AppLogger.info('캐시된 대시보드 데이터 사용', 'CONTENTS');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('대시보드 데이터 로딩 시작', 'CONTENTS');

      // HOT 공연과 예매 가능한 공연을 병렬로 로드
      final results = await Future.wait([
        _performanceService.getHotPerformances(),
        _performanceService.getAvailablePerformances(),
      ]);

      final hotResult = results[0] as ApiResult<List<PerformanceHotItem>>;
      final availableResult = results[1] as ApiResult<List<PerformanceAvailableItem>>;

      if (hotResult.isSuccess && availableResult.isSuccess) {
        _hotPerformances = hotResult.data;
        _availablePerformances = availableResult.data;
        _lastDataLoadTime = DateTime.now();
        
        AppLogger.success(
          '대시보드 데이터 로딩 완료 (HOT: ${_hotPerformances!.length}, Available: ${_availablePerformances!.length})', 
          'CONTENTS'
        );
      } else {
        final errorMsg = hotResult.errorMessage ?? availableResult.errorMessage ?? '데이터 로딩 실패';
        _setError(errorMsg);
      }
    } catch (e) {
      AppLogger.error('대시보드 데이터 로딩 오류', e, null, 'CONTENTS');
      _setError('데이터 로딩 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 전체 공연 목록 로드
  Future<void> loadAllPerformances({int page = 1, int limit = 20}) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('전체 공연 목록 로딩 시작 (페이지: $page)', 'CONTENTS');

      final result = await _performanceService.getAllPerformances(
        page: page,
        limit: limit,
      );

      if (result.isSuccess) {
        if (page == 1) {
          _allPerformances = result.data;
        } else {
          // 페이지네이션: 기존 데이터에 추가
          if (_allPerformances != null) {
            _allPerformances = PerformanceListResponse(
              count: result.data!.count,
              next: result.data!.next,
              previous: result.data!.previous,
              results: [..._allPerformances!.results, ...result.data!.results],
            );
          } else {
            _allPerformances = result.data;
          }
        }
        _currentPage = page;
        
        AppLogger.success('전체 공연 목록 로딩 완료 (총 ${_allPerformances!.count}개)', 'CONTENTS');
      } else {
        _setError(result.errorMessage ?? '공연 목록 로딩 실패');
      }
    } catch (e) {
      AppLogger.error('전체 공연 목록 로딩 오류', e, null, 'CONTENTS');
      _setError('공연 목록 로딩 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 공연 상세 정보 로드
  Future<void> loadPerformanceDetail(int performanceId) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('공연 상세 정보 로딩 시작 (ID: $performanceId)', 'CONTENTS');

      final result = await _performanceService.getPerformanceDetail(performanceId);

      if (result.isSuccess) {
        _selectedPerformance = result.data;
        AppLogger.success('공연 상세 정보 로딩 완료: ${_selectedPerformance!.title}', 'CONTENTS');
      } else {
        _setError(result.errorMessage ?? '공연 상세 정보 로딩 실패');
      }
    } catch (e) {
      AppLogger.error('공연 상세 정보 로딩 오류', e, null, 'CONTENTS');
      _setError('공연 상세 정보 로딩 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 장르별 공연 필터링
  Future<void> filterPerformancesByGenre(String genre) async {
    if (_currentGenreFilter == genre && _filteredPerformances != null) {
      AppLogger.info('이미 필터링된 장르: $genre', 'CONTENTS');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('장르별 공연 필터링 시작: $genre', 'CONTENTS');

      final result = await _performanceService.getPerformancesByGenre(genre);

      if (result.isSuccess) {
        _filteredPerformances = result.data;
        _currentGenreFilter = genre;
        
        AppLogger.success('장르별 공연 필터링 완료: ${_filteredPerformances!.length}개 결과', 'CONTENTS');
      } else {
        _setError(result.errorMessage ?? '장르별 공연 필터링 실패');
      }
    } catch (e) {
      AppLogger.error('장르별 공연 필터링 오류', e, null, 'CONTENTS');
      _setError('장르별 공연 필터링 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 필터 초기화
  void clearGenreFilter() {
    _currentGenreFilter = null;
    _filteredPerformances = null;
    AppLogger.info('장르 필터 초기화', 'CONTENTS');
    notifyListeners();
  }

  /// 선택된 공연 초기화
  void clearSelectedPerformance() {
    _selectedPerformance = null;
    AppLogger.info('선택된 공연 초기화', 'CONTENTS');
    notifyListeners();
  }

  /// 데이터 새로고침
  Future<void> refreshData() async {
    await loadDashboardData(forceRefresh: true);
  }

  /// 다음 페이지 로드
  Future<void> loadNextPage() async {
    if (_allPerformances != null && _allPerformances!.next != null) {
      await loadAllPerformances(page: _currentPage + 1);
    }
  }

  /// 캐시 클리어
  void clearCache() {
    _hotPerformances = null;
    _availablePerformances = null;
    _allPerformances = null;
    _selectedPerformance = null;
    _filteredPerformances = null;
    _lastDataLoadTime = null;
    _currentGenreFilter = null;
    _currentPage = 1;
    
    AppLogger.info('Contents 캐시 클리어', 'CONTENTS');
    notifyListeners();
  }

  /// 에러 메시지 클리어
  void clearError() {
    _clearError();
  }

  // Private methods
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

  @override
  void dispose() {
    AppLogger.info('ContentsProvider dispose', 'CONTENTS');
    super.dispose();
  }
}