import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/data/models/ticket_models.dart';

/// 티켓/예매 관련 API 서비스
class TicketService {
  final DioClient _dioClient;

  TicketService(this._dioClient);

  /// 공연 스케줄 조회
  ///
  /// GET /tickets/performances/{performance_id}/schedule/
  /// 스케줄 선택 페이지에서 사용
  Future<ApiResult<PerformanceSchedule>> getPerformanceSchedule(int performanceId) async {
    AppLogger.info('공연 스케줄 조회 시작 (공연 ID: $performanceId)', 'TICKET');
    
    final endpoint = ApiConstants.performanceSchedule.replaceAll(
      '{performance_id}',
      performanceId.toString(),
    );
    
    return await _dioClient.getResult<PerformanceSchedule>(
      endpoint,
      parser: (data) {
        final schedule = PerformanceSchedule.fromJson(data);
        AppLogger.success('공연 스케줄 조회 성공: ${schedule.title} (${schedule.sessions.length}개 세션)', 'TICKET');
        return schedule;
      },
    );
  }

  /// 세션별 좌석 정보 조회
  ///
  /// GET /tickets/performance/{performance_id}/session/{performance_session_id}/seats/
  /// 좌석 구역 선택 페이지에서 사용
  Future<ApiResult<SessionSeatInfo>> getSessionSeatInfo(
    int performanceId,
    int sessionId,
  ) async {
    AppLogger.info('세션별 좌석 정보 조회 시작 (공연 ID: $performanceId, 세션 ID: $sessionId)', 'TICKET');
    
    final endpoint = ApiConstants.sessionSeats
        .replaceAll('{performance_id}', performanceId.toString())
        .replaceAll('{performance_session_id}', sessionId.toString());
    
    return await _dioClient.getResult<SessionSeatInfo>(
      endpoint,
      parser: (data) {
        final seatInfo = SessionSeatInfo.fromJson(data);
        AppLogger.success('세션별 좌석 정보 조회 성공: ${seatInfo.seatPricingInfo.length}개 구역', 'TICKET');
        return seatInfo;
      },
    );
  }

  /// 좌석 배치 정보 조회
  ///
  /// GET /tickets/performance/{performance_id}/session/{performance_session_id}/zone/{seat_zone}
  /// 좌석 선택 페이지에서 사용
  Future<ApiResult<SeatLayout>> getSeatLayout(
    int performanceId,
    int sessionId,
    String seatZone,
  ) async {
    AppLogger.info('좌석 배치 정보 조회 시작 (공연 ID: $performanceId, 세션 ID: $sessionId, 구역: $seatZone)', 'TICKET');
    
    final endpoint = ApiConstants.seatLayout
        .replaceAll('{performance_id}', performanceId.toString())
        .replaceAll('{performance_session_id}', sessionId.toString())
        .replaceAll('{seat_zone}', seatZone);
    
    return await _dioClient.getResult<SeatLayout>(
      endpoint,
      parser: (data) {
        final seatLayout = SeatLayout.fromJson(data);
        AppLogger.success('좌석 배치 정보 조회 성공: ${seatLayout.totalSeats}석 (사용 가능: ${seatLayout.availableSeatsCount}석)', 'TICKET');
        return seatLayout;
      },
    );
  }

  /// 티켓 생성 (예매하기)
  ///
  /// POST /tickets/create
  /// 결제 완료 후 티켓 발행 시 사용
  Future<ApiResult<CreateTicketResponse>> createTicket(CreateTicketRequest request) async {
    AppLogger.info('티켓 생성 시작 (세션 ID: ${request.performanceSessionId}, 좌석 ID: ${request.seatId})', 'TICKET');
    
    return await _dioClient.postResult<CreateTicketResponse>(
      ApiConstants.createTicket,
      data: request.toJson(),
      parser: (data) {
        final ticketResponse = CreateTicketResponse.fromJson(data);
        AppLogger.success('티켓 생성 성공: ${ticketResponse.ticketId} (상태: ${ticketResponse.statusDisplay})', 'TICKET');
        return ticketResponse;
      },
    );
  }

  /// 티켓 입장 처리
  ///
  /// POST /api/entry/nfc/
  /// NFC 입장 시 사용
  Future<ApiResult<String>> postEntry(String ticketId, int gateId) async {
    AppLogger.info('입장 API 호출 시작 (ticketId: $ticketId, gateId: $gateId)', 'TICKET');

    return await _dioClient.postResult<String>(
      ApiConstants.entryNFC,
      data: {'ticket_id': ticketId, 'gate_id': gateId},
      parser: (data) {
        AppLogger.success('입장 처리 성공', 'TICKET');
        return "200";
      },
    );
  }

  /// 좌석 예약 가능 여부 확인
  ///
  /// 실제 예매 전에 좌석이 아직 사용 가능한지 재확인
  Future<ApiResult<bool>> checkSeatAvailability(
    int performanceId,
    int sessionId,
    String seatZone,
    int seatId,
  ) async {
    AppLogger.info('좌석 예약 가능 여부 확인 (좌석 ID: $seatId)', 'TICKET');

    final seatLayoutResult = await getSeatLayout(
      performanceId,
      sessionId,
      seatZone,
    );

    if (!seatLayoutResult.isSuccess || seatLayoutResult.data == null) {
      AppLogger.error('좌석 레이아웃 조회 실패', seatLayoutResult.errorMessage, null, 'TICKET');
      return ApiResult.failure(seatLayoutResult.errorMessage ?? '좌석 레이아웃 조회에 실패했습니다');
    }

    final seatLayout = seatLayoutResult.data!;
    try {
      final targetSeat = seatLayout.allSeats.firstWhere(
        (seat) => seat.seatId == seatId,
      );
      
      final isAvailable = targetSeat.isAvailable;
      AppLogger.success(
        isAvailable ? '좌석 예약 가능' : '좌석 예약 불가 (${targetSeat.statusDisplay})',
        'TICKET'
      );
      
      return ApiResult.success(isAvailable);
    } catch (e) {
      AppLogger.error('좌석을 찾을 수 없습니다', 'ID: $seatId', null, 'TICKET');
      return ApiResult.failure('좌석을 찾을 수 없습니다: ID $seatId');
    }
  }

  /// 구역별 최저가 조회
  Future<ApiResult<List<SeatPricingInfo>>> getAvailableSeatsWithPrices(
    int performanceId,
    int sessionId,
  ) async {
    AppLogger.info('구역별 가격 정보 조회 시작', 'TICKET');

    final seatInfoResult = await getSessionSeatInfo(performanceId, sessionId);

    if (!seatInfoResult.isSuccess || seatInfoResult.data == null) {
      AppLogger.error('세션 좌석 정보 조회 실패', seatInfoResult.errorMessage, null, 'TICKET');
      return ApiResult.failure(seatInfoResult.errorMessage ?? '세션 좌석 정보 조회에 실패했습니다');
    }

    final seatInfo = seatInfoResult.data!;
    final availableZones = seatInfo.availableZones;

    // 가격순으로 정렬
    availableZones.sort((a, b) => a.price.compareTo(b.price));

    AppLogger.success('구역별 가격 정보 조회 완료 (${availableZones.length}개 구역)', 'TICKET');
    return ApiResult.success(availableZones);
  }
}
