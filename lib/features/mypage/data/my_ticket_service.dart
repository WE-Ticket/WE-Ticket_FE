import 'package:we_ticket/features/mypage/data/payment_history_model.dart';

import '../../../../../core/services/dio_client.dart';
import '../../../../../core/constants/api_endpoints.dart';

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

  /// 구매 이력 조회 (더미 데이터용 - 삭제 예정)
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

  /// 결제 이력 조회 (새로운 API)
  ///
  /// POST /tickets/my-page/payment-history/
  /// 구매 이력 화면에서 사용
  Future<List<PaymentHistory>> getPaymentHistory(
    int userId, {
    String? type,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      print('💳 결제 이력 조회 시작 (사용자 ID: $userId)');

      final requestData = {
        'user_id': userId,
        if (type != null && type.isNotEmpty) 'type': type,
        if (status != null && status.isNotEmpty) 'status': status,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      };

      final response = await _dioClient.post(
        ApiConstants.paymentHistory,
        data: requestData,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final paymentHistories = data
            .map(
              (item) => PaymentHistory.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        print('✅ 결제 이력 조회 성공: ${paymentHistories.length}개');
        return paymentHistories;
      } else {
        throw Exception('결제 이력 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 결제 이력 조회 오류: $e');
      rethrow;
    }
  }

  /// 필터별 결제 이력 조회
  ///
  /// 구매 이력 화면의 필터 탭에 맞춰 데이터를 가져옵니다.
  Future<List<PaymentHistory>> getFilteredPaymentHistory(
    int userId,
    String filter, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      print('🔍 필터별 결제 이력 조회 시작 (필터: $filter)');

      String? apiType;
      String? apiStatus;

      // 필터에 따른 API 파라미터 설정 (새로운 TYPE_CHOICES 반영)
      switch (filter) {
        case '구매 내역':
          // buy_ticket과 buy_transfer_ticket 모두 포함
          // 전체 조회 후 클라이언트에서 필터링
          break;
        case '판매 내역':
          apiType = 'sell_transfer_ticket';
          break;
        case '취소/환불':
          apiType = 'cancel_ticket';
          break;
        default: // 전체 거래
          break;
      }

      // API 호출
      final allHistories = await getPaymentHistory(
        userId,
        type: apiType,
        status: apiStatus,
        startDate: startDate,
        endDate: endDate,
      );

      // 클라이언트 사이드 필터링 (필요한 경우)
      List<PaymentHistory> filteredHistories;

      switch (filter) {
        case '구매 내역':
          filteredHistories = allHistories
              .where(
                (history) =>
                    history.paymentType == 'buy_ticket' ||
                    history.paymentType == 'buy_transfer_ticket',
              )
              .toList();
          break;
        case '판매 내역':
          filteredHistories = allHistories
              .where((history) => history.paymentType == 'sell_transfer_ticket')
              .toList();
          break;
        case '취소/환불':
          filteredHistories = allHistories
              .where((history) => history.paymentType == 'cancel_ticket')
              .toList();
          break;
        default: // 전체 거래
          filteredHistories = allHistories;
          break;
      }

      print('✅ 필터별 결제 이력 조회 완료: ${filteredHistories.length}개');
      return filteredHistories;
    } catch (e) {
      print('❌ 필터별 결제 이력 조회 오류: $e');
      rethrow;
    }
  }
}
