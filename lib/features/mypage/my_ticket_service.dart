import '../../../../core/services/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';

/// 내 티켓 관련 API 서비스
class MyTicketService {
  final DioClient _dioClient;

  MyTicketService(this._dioClient);

  /// 내 티켓 목록 조회
  ///
  /// POST /tickets/my-page/owned-ticket-list/
  /// 내 티켓 관리 화면에서 사용
  Future<List<Map<String, dynamic>>> getOwnedTickets(
    int userId, {
    String? state,
  }) async {
    try {
      print('🎫 내 티켓 목록 조회 시작 (사용자 ID: $userId, 상태: $state)');

      final requestData = {
        'user_id': userId,
        if (state != null && state.isNotEmpty) 'state': state,
      };

      final response = await _dioClient.post(
        ApiConstants.myTickets,
        data: requestData,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final tickets = data.cast<Map<String, dynamic>>();

        print('✅ 내 티켓 목록 조회 성공: ${tickets.length}개');
        return tickets;
      } else {
        throw Exception('내 티켓 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 내 티켓 목록 조회 오류: $e');
      rethrow;
    }
  }

  /// 티켓 상세 정보 조회
  ///
  /// POST /tickets/my-ticket-detail/
  /// 티켓 상세 화면에서 사용
  Future<Map<String, dynamic>> getTicketDetail(String nftTicketId) async {
    try {
      print('🎫 티켓 상세 정보 조회 시작 (티켓 ID: $nftTicketId)');

      final requestData = {'nft_ticket_id': nftTicketId};

      final response = await _dioClient.post(
        ApiConstants.myTicketDetail,
        data: requestData,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        print('✅ 티켓 상세 정보 조회 성공');
        return data;
      } else {
        throw Exception('티켓 상세 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 티켓 상세 정보 조회 오류: $e');
      rethrow;
    }
  }

  /// 구매 이력 조회
  ///
  /// POST /tickets/my-page/touched-ticket-list/
  /// 구매 이력 화면에서 사용
  Future<List<Map<String, dynamic>>> getTouchedTickets(
    int userId, {
    String? state,
    String? startDate,
    String? endDate,
  }) async {
    try {
      print('📋 구매 이력 조회 시작 (사용자 ID: $userId)');

      final requestData = {
        'user_id': userId,
        if (state != null && state.isNotEmpty) 'state': state,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      };

      final response = await _dioClient.post(
        ApiConstants.myPurchases,
        data: requestData,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final tickets = data.cast<Map<String, dynamic>>();

        print('✅ 구매 이력 조회 성공: ${tickets.length}개');
        return tickets;
      } else {
        throw Exception('구매 이력 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 구매 이력 조회 오류: $e');
      rethrow;
    }
  }
}
