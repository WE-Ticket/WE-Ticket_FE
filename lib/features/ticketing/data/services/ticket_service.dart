import '../../../../core/services/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/ticket_models.dart';

/// 티켓/예매 관련 API 서비스
class TicketService {
  final DioClient _dioClient;

  TicketService(this._dioClient);

  /// 공연 스케줄 조회
  ///
  /// GET /tickets/performances/{performance_id}/schedule/
  /// 스케줄 선택 페이지에서 사용
  Future<PerformanceSchedule> getPerformanceSchedule(int performanceId) async {
    try {
      print('!!1 공연 스케줄 조회 시작 (공연 ID: $performanceId)');
      final endpoint = ApiConstants.performanceSchedule.replaceAll(
        '{performance_id}',
        performanceId.toString(),
      );
      final response = await _dioClient.get(endpoint);

      if (response.statusCode == 200) {
        final schedule = PerformanceSchedule.fromJson(response.data);
        print(
          '✅ 공연 스케줄 조회 성공: ${schedule.title} (${schedule.sessions.length}개 세션)',
        );
        return schedule;
      } else {
        throw Exception('공연 스케줄 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 공연 스케줄 조회 오류 (공연 ID: $performanceId): $e');
      rethrow;
    }
  }

  /// 세션별 좌석 정보 조회
  ///
  /// GET /tickets/performance/{performance_id}/session/{performance_session_id}/seats/
  /// 좌석 구역 선택 페이지에서 사용
  Future<SessionSeatInfo> getSessionSeatInfo(
    int performanceId,
    int sessionId,
  ) async {
    try {
      print('!!! 세션별 좌석 정보 조회 시작 (공연 ID: $performanceId, 세션 ID: $sessionId)');
      final endpoint = ApiConstants.sessionSeats
          .replaceAll('{performance_id}', performanceId.toString())
          .replaceAll('{performance_session_id}', sessionId.toString());
      final response = await _dioClient.get(endpoint);

      if (response.statusCode == 200) {
        final seatInfo = SessionSeatInfo.fromJson(response.data);
        print('✅ 세션별 좌석 정보 조회 성공: ${seatInfo.seatPricingInfo.length}개 구역');
        return seatInfo;
      } else {
        throw Exception('세션별 좌석 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 세션별 좌석 정보 조회 오류 (공연 ID: $performanceId, 세션 ID: $sessionId): $e');
      rethrow;
    }
  }

  /// 좌석 배치 정보 조회
  ///
  /// GET /tickets/performance/{performance_id}/session/{performance_session_id}/zone/{seat_zone}
  /// 좌석 선택 페이지에서 사용
  Future<SeatLayout> getSeatLayout(
    int performanceId,
    int sessionId,
    String seatZone,
  ) async {
    try {
      print(
        '!!! 좌석 배치 정보 조회 시작 (공연 ID: $performanceId, 세션 ID: $sessionId, 구역: $seatZone)',
      );
      final endpoint = ApiConstants.seatLayout
          .replaceAll('{performance_id}', performanceId.toString())
          .replaceAll('{performance_session_id}', sessionId.toString())
          .replaceAll('{seat_zone}', seatZone);
      final response = await _dioClient.get(endpoint);

      if (response.statusCode == 200) {
        final seatLayout = SeatLayout.fromJson(response.data);
        print(
          '✅ 좌석 배치 정보 조회 성공: ${seatLayout.totalSeats}석 (사용 가능: ${seatLayout.availableSeatsCount}석)',
        );
        return seatLayout;
      } else {
        throw Exception('좌석 배치 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print(
        '❌ 좌석 배치 정보 조회 오류 (공연 ID: $performanceId, 세션 ID: $sessionId, 구역: $seatZone): $e',
      );
      rethrow;
    }
  }

  /// 티켓 생성 (예매하기)
  ///
  /// POST /tickets/create
  /// 결제 완료 후 티켓 발행 시 사용
  Future<CreateTicketResponse> createTicket(CreateTicketRequest request) async {
    try {
      print(
        '!!! 티켓 생성 시작 (세션 ID: ${request.performanceSessionId}, 좌석 ID: ${request.seatId})',
      );
      final response = await _dioClient.post(
        ApiConstants.createTicket,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final ticketResponse = CreateTicketResponse.fromJson(response.data);
        print(
          '✅ 티켓 생성 성공: ${ticketResponse.ticketId} (상태: ${ticketResponse.statusDisplay})',
        );
        return ticketResponse;
      } else {
        throw Exception('티켓 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 티켓 생성 오류: $e');
      rethrow;
    }
  }

  Future<String> postEntry(String ticketId, int gateId) async {
    try {
      print('📤 입장 API 호출 → ticketId: $ticketId, gateId: $gateId');

      final response = await _dioClient.post(
        ApiConstants.entryNFC,
        data: {'ticket_id': ticketId, 'gate_id': gateId},
      );

      print('응답!!!1');
      print(response);

      if (response.statusCode == 200) {
        return "200";
      } else {
        throw Exception('티켓 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 티켓 생성 오류: $e');
      rethrow;
    }
  }

  /// 좌석 예약 가능 여부 확인
  ///
  /// 실제 예매 전에 좌석이 아직 사용 가능한지 재확인
  Future<bool> checkSeatAvailability(
    int performanceId,
    int sessionId,
    String seatZone,
    int seatId,
  ) async {
    try {
      print('!!! 좌석 예약 가능 여부 확인 (좌석 ID: $seatId)');

      final seatLayout = await getSeatLayout(
        performanceId,
        sessionId,
        seatZone,
      );

      final targetSeat = seatLayout.allSeats.firstWhere(
        (seat) => seat.seatId == seatId,
        orElse: () => throw Exception('좌석을 찾을 수 없습니다: ID $seatId'),
      );

      final isAvailable = targetSeat.isAvailable;
      print(
        isAvailable ? '✅ 좌석 예약 가능' : '❌ 좌석 예약 불가 (${targetSeat.statusDisplay})',
      );

      return isAvailable;
    } catch (e) {
      print('❌ 좌석 예약 가능 여부 확인 오류: $e');
      rethrow;
    }
  }

  /// 구역별 최저가 조회
  Future<List<SeatPricingInfo>> getAvailableSeatsWithPrices(
    int performanceId,
    int sessionId,
  ) async {
    try {
      print('!!! 구역별 가격 정보 조회 시작');

      final seatInfo = await getSessionSeatInfo(performanceId, sessionId);
      final availableZones = seatInfo.availableZones;

      // 가격순으로 정렬
      availableZones.sort((a, b) => a.price.compareTo(b.price));

      print('✅ 구역별 가격 정보 조회 완료 (${availableZones.length}개 구역)');
      return availableZones;
    } catch (e) {
      print('❌ 구역별 가격 정보 조회 오류: $e');
      rethrow;
    }
  }
}
