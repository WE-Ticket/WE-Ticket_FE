import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/my_ticket.dart';
import '../../domain/entities/payment_history.dart';
import '../../domain/use_cases/get_owned_tickets_use_case.dart';
import '../../domain/use_cases/get_ticket_detail_use_case.dart';
import '../../domain/use_cases/get_payment_history_use_case.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_logger.dart';

/// MyPage 기능을 관리하는 Provider
/// 내 티켓 목록, 티켓 상세 정보, 결제 내역 등의 상태를 관리합니다.
class MyPageProvider extends ChangeNotifier {
  final GetOwnedTicketsUseCase _getOwnedTicketsUseCase;
  final GetTicketDetailUseCase _getTicketDetailUseCase;
  final GetPaymentHistoryUseCase _getPaymentHistoryUseCase;

  // 상태 관리
  bool _isLoading = false;
  String? _errorMessage;

  // 데이터
  List<MyTicket>? _ownedTickets;
  List<MyTicket>? _touchedTickets;
  MyTicket? _selectedTicket;
  List<PaymentHistory>? _paymentHistory;

  // 필터 상태
  String? _currentTicketFilter;
  String? _currentPaymentFilter;

  // 캐시 관리
  DateTime? _lastTicketsLoadTime;
  DateTime? _lastPaymentLoadTime;

  MyPageProvider({
    required GetOwnedTicketsUseCase getOwnedTicketsUseCase,
    required GetTicketDetailUseCase getTicketDetailUseCase,
    required GetPaymentHistoryUseCase getPaymentHistoryUseCase,
  })  : _getOwnedTicketsUseCase = getOwnedTicketsUseCase,
        _getTicketDetailUseCase = getTicketDetailUseCase,
        _getPaymentHistoryUseCase = getPaymentHistoryUseCase;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MyTicket>? get ownedTickets => _ownedTickets;
  List<MyTicket>? get touchedTickets => _touchedTickets;
  MyTicket? get selectedTicket => _selectedTicket;
  List<PaymentHistory>? get paymentHistory => _paymentHistory;
  String? get currentTicketFilter => _currentTicketFilter;
  String? get currentPaymentFilter => _currentPaymentFilter;

  /// 캐시된 티켓 데이터가 유효한지 확인 (10분 이내)
  bool get isTicketCacheValid {
    if (_lastTicketsLoadTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastTicketsLoadTime!);
    return difference.inMinutes < 10;
  }

  /// 캐시된 결제 데이터가 유효한지 확인 (10분 이내)
  bool get isPaymentCacheValid {
    if (_lastPaymentLoadTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastPaymentLoadTime!);
    return difference.inMinutes < 10;
  }

  /// 내 티켓 목록 로드
  Future<void> loadOwnedTickets(
    int userId, {
    String? state,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && 
        isTicketCacheValid && 
        _ownedTickets != null && 
        _currentTicketFilter == state) {
      AppLogger.info('캐시된 티켓 데이터 사용', 'MYPAGE');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('내 티켓 목록 로딩 시작 (userId: $userId, state: $state)', 'MYPAGE');

      final result = await _getOwnedTicketsUseCase.call(
        GetOwnedTicketsParams(userId: userId, state: state),
      );

      result.fold(
        (failure) {
          final errorMsg = _mapFailureToMessage(failure);
          AppLogger.error('내 티켓 목록 로딩 실패: $errorMsg', null, null, 'MYPAGE');
          _setError(errorMsg);
        },
        (tickets) {
          _ownedTickets = tickets;
          _currentTicketFilter = state;
          _lastTicketsLoadTime = DateTime.now();
          AppLogger.success('내 티켓 목록 로딩 완료: ${tickets.length}개', 'MYPAGE');
        },
      );
    } catch (e) {
      AppLogger.error('내 티켓 목록 로딩 예외', e, null, 'MYPAGE');
      _setError('티켓 목록 로딩 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 티켓 상세 정보 로드
  Future<void> loadTicketDetail(String nftTicketId) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('티켓 상세 정보 로딩 시작 (nftTicketId: $nftTicketId)', 'MYPAGE');

      final result = await _getTicketDetailUseCase.call(
        GetTicketDetailParams(nftTicketId: nftTicketId),
      );

      result.fold(
        (failure) {
          final errorMsg = _mapFailureToMessage(failure);
          AppLogger.error('티켓 상세 정보 로딩 실패: $errorMsg', null, null, 'MYPAGE');
          _setError(errorMsg);
        },
        (ticket) {
          _selectedTicket = ticket;
          AppLogger.success('티켓 상세 정보 로딩 완료: ${ticket.title}', 'MYPAGE');
        },
      );
    } catch (e) {
      AppLogger.error('티켓 상세 정보 로딩 예외', e, null, 'MYPAGE');
      _setError('티켓 상세 정보 로딩 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 결제 내역 로드
  Future<void> loadPaymentHistory(
    int userId, {
    String? filter,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && 
        isPaymentCacheValid && 
        _paymentHistory != null && 
        _currentPaymentFilter == filter) {
      AppLogger.info('캐시된 결제 내역 데이터 사용', 'MYPAGE');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('결제 내역 로딩 시작 (userId: $userId, filter: $filter)', 'MYPAGE');

      final result = await _getPaymentHistoryUseCase.call(
        GetPaymentHistoryParams(userId: userId, filter: filter),
      );

      result.fold(
        (failure) {
          final errorMsg = _mapFailureToMessage(failure);
          AppLogger.error('결제 내역 로딩 실패: $errorMsg', null, null, 'MYPAGE');
          _setError(errorMsg);
        },
        (histories) {
          _paymentHistory = histories;
          _currentPaymentFilter = filter;
          _lastPaymentLoadTime = DateTime.now();
          AppLogger.success('결제 내역 로딩 완료: ${histories.length}개', 'MYPAGE');
        },
      );
    } catch (e) {
      AppLogger.error('결제 내역 로딩 예외', e, null, 'MYPAGE');
      _setError('결제 내역 로딩 중 오료가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 사용자 초기 데이터 로드 (티켓 목록 + 결제 내역)
  Future<void> loadUserData(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('사용자 MyPage 데이터 로딩 시작 (userId: $userId)', 'MYPAGE');

      // 티켓 목록과 결제 내역을 병렬로 로드
      await Future.wait([
        loadOwnedTickets(userId, forceRefresh: true),
        loadPaymentHistory(userId, forceRefresh: true),
      ]);

      AppLogger.success('사용자 MyPage 데이터 로딩 완료', 'MYPAGE');
    } catch (e) {
      AppLogger.error('사용자 MyPage 데이터 로딩 예외', e, null, 'MYPAGE');
      _setError('사용자 데이터 로딩 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 결제 통계 생성
  Map<String, dynamic> generatePaymentStatistics() {
    if (_paymentHistory == null || _paymentHistory!.isEmpty) {
      return {
        'totalCount': 0,
        'purchaseCount': 0,
        'sellCount': 0,
        'cancelCount': 0,
        'totalAmount': 0,
        'averageAmount': 0,
      };
    }

    final histories = _paymentHistory!;
    
    return {
      'totalCount': histories.length,
      'purchaseCount': histories.where((h) => h.isPurchase || h.isTransferBuy).length,
      'sellCount': histories.where((h) => h.isTransferSell).length,
      'cancelCount': histories.where((h) => h.isCancel).length,
      'completedCount': histories.where((h) => h.isCompleted).length,
      'pendingCount': histories.where((h) => h.isPending).length,
      'totalAmount': histories.fold<int>(0, (sum, h) => sum + h.price),
      'averageAmount': histories.fold<int>(0, (sum, h) => sum + h.price) ~/ histories.length,
      'lastPaymentDate': histories.isEmpty
          ? null
          : histories
              .map((h) => h.paymentDate)
              .reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }

  /// 선택된 티켓 클리어
  void clearSelectedTicket() {
    _selectedTicket = null;
    AppLogger.info('선택된 티켓 클리어', 'MYPAGE');
    notifyListeners();
  }

  /// 데이터 새로고침
  Future<void> refreshData(int userId) async {
    await Future.wait([
      loadOwnedTickets(userId, forceRefresh: true),
      loadPaymentHistory(userId, forceRefresh: true),
    ]);
  }

  /// 캐시 클리어
  void clearCache() {
    _ownedTickets = null;
    _touchedTickets = null;
    _selectedTicket = null;
    _paymentHistory = null;
    _currentTicketFilter = null;
    _currentPaymentFilter = null;
    _lastTicketsLoadTime = null;
    _lastPaymentLoadTime = null;
    
    AppLogger.info('MyPage 캐시 클리어', 'MYPAGE');
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

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return '네트워크 연결을 확인해주세요';
    } else {
      return '알 수 없는 오류가 발생했습니다';
    }
  }

  @override
  void dispose() {
    AppLogger.info('MyPageProvider dispose', 'MYPAGE');
    super.dispose();
  }
}