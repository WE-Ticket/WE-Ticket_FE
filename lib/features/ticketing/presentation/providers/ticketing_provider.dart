import 'package:flutter/foundation.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/services/ticket_service.dart';
import '../../data/models/ticket_models.dart';

/// Ticketing 기능을 관리하는 Provider
/// 티켓 예매, 좌석 선택, 결제 등의 상태를 관리합니다.
class TicketingProvider extends ChangeNotifier {
  final TicketService _ticketService;

  // 상태 관리
  bool _isLoading = false;
  String? _errorMessage;

  // 예매 플로우 데이터
  PerformanceSchedule? _scheduleData;
  SessionSeatInfo? _seatData;
  List<Seat>? _selectedSeats;
  Map<String, dynamic>? _paymentData;
  
  // 현재 선택된 정보
  int? _selectedPerformanceId;
  int? _selectedSessionId;
  String? _selectedZone;
  
  // NFT 발급 상태
  bool _isNftIssuing = false;
  CreateTicketResponse? _nftResult;

  TicketingProvider({
    required TicketService ticketService,
  })  : _ticketService = ticketService;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PerformanceSchedule? get scheduleData => _scheduleData;
  SessionSeatInfo? get seatData => _seatData;
  List<Seat>? get selectedSeats => _selectedSeats;
  Map<String, dynamic>? get paymentData => _paymentData;
  int? get selectedPerformanceId => _selectedPerformanceId;
  int? get selectedSessionId => _selectedSessionId;
  String? get selectedZone => _selectedZone;
  bool get isNftIssuing => _isNftIssuing;
  CreateTicketResponse? get nftResult => _nftResult;

  /// 공연 스케줄 로드
  Future<void> loadPerformanceSchedule(int performanceId) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('공연 스케줄 로딩 시작 (performanceId: $performanceId)', 'TICKETING');
      
      final result = await _ticketService.getPerformanceSchedule(performanceId);
      
      if (result.isSuccess) {
        _scheduleData = result.data;
        _selectedPerformanceId = performanceId;
        AppLogger.success('공연 스케줄 로딩 완료: ${result.data!.sessions.length}개 세션', 'TICKETING');
      } else {
        _setError(result.errorMessage ?? '공연 스케줄 로딩 실패');
      }
    } catch (e) {
      AppLogger.error('공연 스케줄 로딩 예외', e, null, 'TICKETING');
      _setError('공연 스케줄 로딩 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 세션 좌석 정보 로드
  Future<void> loadSessionSeatInfo(int performanceId, int sessionId) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('세션 좌석 정보 로딩 시작 (sessionId: $sessionId)', 'TICKETING');
      
      final result = await _ticketService.getSessionSeatInfo(performanceId, sessionId);
      
      if (result.isSuccess) {
        _seatData = result.data;
        _selectedSessionId = sessionId;
        AppLogger.success('세션 좌석 정보 로딩 완료: ${result.data!.seatPricingInfo.length}개 구역', 'TICKETING');
      } else {
        _setError(result.errorMessage ?? '좌석 정보 로딩 실패');
      }
    } catch (e) {
      AppLogger.error('세션 좌석 정보 로딩 예외', e, null, 'TICKETING');
      _setError('좌석 정보 로딩 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 구역별 좌석 레이아웃 로드
  Future<SeatLayout?> loadSeatLayout(
    int performanceId,
    int sessionId,
    String zone,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('좌석 레이아웃 로딩 시작 (zone: $zone)', 'TICKETING');
      
      final result = await _ticketService.getSeatLayout(performanceId, sessionId, zone);
      
      if (result.isSuccess) {
        _selectedZone = zone;
        AppLogger.success('좌석 레이아웃 로딩 완료: ${result.data!.totalSeats}개 좌석', 'TICKETING');
        return result.data;
      } else {
        _setError(result.errorMessage ?? '좌석 레이아웃 로딩 실패');
        return null;
      }
    } catch (e) {
      AppLogger.error('좌석 레이아웃 로딩 예외', e, null, 'TICKETING');
      _setError('좌석 레이아웃 로딩 중 오류가 발생했습니다');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 좌석 선택
  void selectSeats(List<Seat> seats) {
    _selectedSeats = seats;
    AppLogger.info('좌석 선택 완료: ${seats.length}개', 'TICKETING');
    notifyListeners();
  }

  /// 결제 데이터 설정
  void setPaymentData(Map<String, dynamic> paymentData) {
    _paymentData = paymentData;
    AppLogger.info('결제 데이터 설정 완료', 'TICKETING');
    notifyListeners();
  }

  /// 티켓 생성 (NFT 발급)
  Future<void> createTickets(CreateTicketRequest request) async {
    _isNftIssuing = true;
    _clearError();

    try {
      AppLogger.info('NFT 티켓 발급 시작', 'TICKETING');
      
      final result = await _ticketService.createTicket(request);
      
      if (result.isSuccess) {
        _nftResult = result.data;
        AppLogger.success('NFT 티켓 발급 완료', 'TICKETING');
      } else {
        _setError(result.errorMessage ?? 'NFT 티켓 발급 실패');
      }
    } catch (e) {
      AppLogger.error('NFT 티켓 발급 예외', e, null, 'TICKETING');
      _setError('NFT 티켓 발급 중 오류가 발생했습니다');
    } finally {
      _isNftIssuing = false;
      notifyListeners();
    }
  }

  /// 예매 플로우 초기화
  void resetBookingFlow() {
    _scheduleData = null;
    _seatData = null;
    _selectedSeats = null;
    _paymentData = null;
    _selectedPerformanceId = null;
    _selectedSessionId = null;
    _selectedZone = null;
    _nftResult = null;
    _clearError();
    AppLogger.info('예매 플로우 초기화', 'TICKETING');
    notifyListeners();
  }

  /// 좌석 선택 초기화
  void clearSelectedSeats() {
    _selectedSeats = null;
    AppLogger.info('좌석 선택 초기화', 'TICKETING');
    notifyListeners();
  }

  /// NFT 결과 클리어
  void clearNftResult() {
    _nftResult = null;
    AppLogger.info('NFT 결과 클리어', 'TICKETING');
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
    AppLogger.info('TicketingProvider dispose', 'TICKETING');
    super.dispose();
  }
}