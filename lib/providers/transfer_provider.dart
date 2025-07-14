import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/transfer_models.dart';

/// 양도 마켓 관련 상태 관리를 위한 Provider
///
/// 양도 티켓 리스트, 상세 정보, 내 양도 관리 등의 상태를 관리합니다.
class TransferProvider extends ChangeNotifier {
  final ApiService _apiService;

  // 로딩 상태 관리
  bool _isLoading = false;
  String? _errorMessage;

  // 양도 마켓 데이터
  List<TransferTicketItem>? _transferTickets;
  TransferTicketDetail? _currentTransferDetail;

  // 내 양도 관리 데이터
  List<MyTransferTicket>? _myRegisteredTickets;
  List<TransferableTicket>? _myTransferableTickets;

  // 고유번호 관리
  Map<int, TransferUniqueCode> _uniqueCodes = {};

  // 필터링 상태
  int? _selectedPerformanceId;
  String _searchQuery = '';

  // 캐시 관리
  DateTime? _lastDataLoadTime;

  /// 생성자
  TransferProvider(this._apiService);

  /// Getter들
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TransferTicketItem>? get transferTickets => _transferTickets;
  TransferTicketDetail? get currentTransferDetail => _currentTransferDetail;
  List<MyTransferTicket>? get myRegisteredTickets => _myRegisteredTickets;
  List<TransferableTicket>? get myTransferableTickets => _myTransferableTickets;
  int? get selectedPerformanceId => _selectedPerformanceId;
  String get searchQuery => _searchQuery;

  /// 캐시된 데이터가 유효한지 확인 (3분 이내)
  bool get isCacheValid {
    if (_lastDataLoadTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastDataLoadTime!);
    return difference.inMinutes < 3;
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

  /// 양도 마켓 티켓 리스트 로드
  Future<void> loadTransferTickets({
    bool forceRefresh = false,
    int? performanceId,
  }) async {
    try {
      // 캐시가 유효하고 강제 새로고침이 아니며 동일한 필터라면 스킵
      if (!forceRefresh &&
          isCacheValid &&
          _transferTickets != null &&
          _selectedPerformanceId == performanceId) {
        print('📦 캐시된 양도 티켓 데이터 사용');
        return;
      }

      _setLoading(true);
      clearError();
      _selectedPerformanceId = performanceId;

      print('🔄 양도 티켓 리스트 새로 로드');

      final transferList = await _apiService.transfer.getTransferTicketList(
        performanceId: performanceId,
      );

      _transferTickets = transferList.results;
      _lastDataLoadTime = DateTime.now();

      print('✅ 양도 티켓 리스트 로드 완료 (${_transferTickets!.length}개)');
    } catch (e) {
      print('❌ 양도 티켓 리스트 로드 실패: $e');
      _setError('양도 티켓 목록을 불러올 수 없습니다. 다시 시도해주세요.');
    } finally {
      _setLoading(false);
    }
  }

  /// 양도 티켓 상세 정보 로드 (공개)
  Future<void> loadPublicTransferDetail(int transferTicketId) async {
    try {
      _setLoading(true);
      clearError();

      print('🔍 공개 양도 티켓 상세 로드: $transferTicketId');

      final detail = await _apiService.transfer.getPublicTransferDetail(
        transferTicketId,
      );
      _currentTransferDetail = detail;

      print('✅ 공개 양도 티켓 상세 로드 완료');
    } catch (e) {
      print('❌ 공개 양도 티켓 상세 로드 실패: $e');
      _setError('양도 티켓 정보를 불러올 수 없습니다.');
    } finally {
      _setLoading(false);
    }
  }

  /// 양도 티켓 상세 정보 로드 (비공개)
  Future<void> loadPrivateTransferDetail(String uniqueCode) async {
    try {
      _setLoading(true);
      clearError();

      print('🔐 비공개 양도 티켓 상세 로드');

      final detail = await _apiService.transfer.getPrivateTransferDetail(
        uniqueCode,
      );
      _currentTransferDetail = detail;

      print('✅ 비공개 양도 티켓 상세 로드 완료');
    } catch (e) {
      print('❌ 비공개 양도 티켓 상세 로드 실패: $e');
      _setError('고유번호가 유효하지 않거나 만료되었습니다.');
    } finally {
      _setLoading(false);
    }
  }

  /// 내 양도 등록 티켓 리스트 로드
  Future<void> loadMyRegisteredTickets({
    required int userId,
    String? startDate,
    String? endDate,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && _myRegisteredTickets != null) {
        print('📦 캐시된 내 양도 등록 티켓 데이터 사용');
        return;
      }

      _setLoading(true);
      clearError();

      print('📋 내 양도 등록 티켓 리스트 로드');

      final tickets = await _apiService.transfer.getMyRegisteredTickets(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      _myRegisteredTickets = tickets;

      print('✅ 내 양도 등록 티켓 리스트 로드 완료 (${tickets.length}개)');
    } catch (e) {
      print('❌ 내 양도 등록 티켓 리스트 로드 실패: $e');
      _setError('내 양도 등록 티켓 목록을 불러올 수 없습니다.');
    } finally {
      _setLoading(false);
    }
  }

  /// 내 양도 가능 티켓 리스트 로드
  Future<void> loadMyTransferableTickets({
    required int userId,
    String? startDate,
    String? endDate,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && _myTransferableTickets != null) {
        print('📦 캐시된 내 양도 가능 티켓 데이터 사용');
        return;
      }

      _setLoading(true);
      clearError();

      print('🎟️ 내 양도 가능 티켓 리스트 로드');

      final tickets = await _apiService.transfer.getMyTransferableTickets(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      _myTransferableTickets = tickets;

      print('✅ 내 양도 가능 티켓 리스트 로드 완료 (${tickets.length}개)');
    } catch (e) {
      print('❌ 내 양도 가능 티켓 리스트 로드 실패: $e');
      _setError('내 양도 가능 티켓 목록을 불러올 수 없습니다.');
    } finally {
      _setLoading(false);
    }
  }

  /// 고유번호 조회
  Future<TransferUniqueCode?> getUniqueCode(int transferTicketId) async {
    try {
      // 캐시된 고유번호가 있고 만료되지 않았다면 반환
      if (_uniqueCodes.containsKey(transferTicketId)) {
        final cachedCode = _uniqueCodes[transferTicketId]!;
        if (!cachedCode.isExpired) {
          print('📦 캐시된 고유번호 사용');
          return cachedCode;
        }
      }

      _setLoading(true);
      clearError();

      print('🔑 고유번호 조회');

      final uniqueCode = await _apiService.transfer.getUniqueCode(
        transferTicketId,
      );

      // 캐시에 저장
      _uniqueCodes[transferTicketId] = uniqueCode;

      print('✅ 고유번호 조회 완료');
      return uniqueCode;
    } catch (e) {
      print('❌ 고유번호 조회 실패: $e');
      _setError('고유번호를 조회할 수 없습니다.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 고유번호 재발급
  Future<TransferUniqueCode?> regenerateUniqueCode(int transferTicketId) async {
    try {
      _setLoading(true);
      clearError();

      print('🔄 고유번호 재발급');

      final uniqueCode = await _apiService.transfer.regenerateUniqueCode(
        transferTicketId,
      );

      // 캐시 업데이트
      _uniqueCodes[transferTicketId] = uniqueCode;

      print('✅ 고유번호 재발급 완료');
      return uniqueCode;
    } catch (e) {
      print('❌ 고유번호 재발급 실패: $e');
      _setError('고유번호를 재발급할 수 없습니다.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 검색어 설정
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 공연 필터 설정
  void setPerformanceFilter(int? performanceId) {
    if (_selectedPerformanceId != performanceId) {
      _selectedPerformanceId = performanceId;
      // 필터가 변경되면 데이터를 새로 로드
      loadTransferTickets(forceRefresh: true, performanceId: performanceId);
    }
  }

  /// 필터된 양도 티켓 리스트 반환
  List<TransferTicketItem> get filteredTransferTickets {
    if (_transferTickets == null) return [];

    var filtered = _transferTickets!;

    // 검색어 필터링
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((ticket) {
        return ticket.performanceTitle.toLowerCase().contains(query) ||
            ticket.performerName.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  /// 데이터 새로고침
  Future<void> refreshData({int? userId}) async {
    final futures = <Future>[];

    // 양도 마켓 데이터 새로고침
    futures.add(
      loadTransferTickets(
        forceRefresh: true,
        performanceId: _selectedPerformanceId,
      ),
    );

    // 사용자 ID가 있으면 내 데이터도 새로고침
    if (userId != null) {
      futures.add(loadMyRegisteredTickets(userId: userId, forceRefresh: true));
      futures.add(
        loadMyTransferableTickets(userId: userId, forceRefresh: true),
      );
    }

    await Future.wait(futures);
  }

  /// 캐시 클리어
  void clearCache() {
    _transferTickets = null;
    _currentTransferDetail = null;
    _myRegisteredTickets = null;
    _myTransferableTickets = null;
    _uniqueCodes.clear();
    _lastDataLoadTime = null;
    notifyListeners();
  }

  /// Provider 리소스 정리
  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
