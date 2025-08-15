import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/mypage_models.dart';

/// MyPage 관련 API 서비스
class MyPageService {
  final DioClient _dioClient;

  MyPageService(this._dioClient);

  /// 내 티켓 목록 조회
  Future<ApiResult<List<MyTicketModel>>> getOwnedTickets(
    int userId, {
    String? state,
  }) async {
    return await _dioClient.postResult<List<MyTicketModel>>(
      ApiConstants.myTickets,
      data: {
        'user_id': userId,
        if (state != null && state.isNotEmpty) 'state': state,
      },
      parser: (data) {
        final List<dynamic> listData = data;
        final tickets = listData
            .map((json) => MyTicketModel.fromJson(json))
            .toList();
        AppLogger.success('내 티켓 목록 ${tickets.length}개 조회 성공', 'MYPAGE_SERVICE');
        return tickets;
      },
    );
  }

  /// 티켓 상세 정보 조회
  Future<ApiResult<MyTicketModel>> getTicketDetail(String nftTicketId) async {
    return await _dioClient.postResult<MyTicketModel>(
      ApiConstants.myTicketDetail,
      data: {'nft_ticket_id': nftTicketId},
      parser: (data) {
        final ticket = MyTicketModel.fromJson(data);
        AppLogger.success('티켓 상세 정보 조회 성공: ${ticket.title}', 'MYPAGE_SERVICE');
        return ticket;
      },
    );
  }

  /// 결제 내역 조회
  Future<ApiResult<List<PaymentHistoryModel>>> getPaymentHistory(
    int userId, {
    String? filter,
  }) async {
    return await _dioClient.postResult<List<PaymentHistoryModel>>(
      ApiConstants.paymentHistory,
      data: {
        'user_id': userId,
        if (filter != null && filter.isNotEmpty) 'filter': filter,
      },
      parser: (data) {
        final List<dynamic> listData = data;
        final histories = listData
            .map((json) => PaymentHistoryModel.fromJson(json))
            .toList();
        AppLogger.success('결제 내역 ${histories.length}개 조회 성공', 'MYPAGE_SERVICE');
        return histories;
      },
    );
  }

  /// 구매한 티켓 목록 조회 (터치한 티켓)
  Future<ApiResult<List<MyTicketModel>>> getTouchedTickets(int userId) async {
    return await _dioClient.postResult<List<MyTicketModel>>(
      ApiConstants.myPurchases,
      data: {'user_id': userId},
      parser: (data) {
        final List<dynamic> listData = data;
        final tickets = listData
            .map((json) => MyTicketModel.fromJson(json))
            .toList();
        AppLogger.success('구매한 티켓 목록 ${tickets.length}개 조회 성공', 'MYPAGE_SERVICE');
        return tickets;
      },
    );
  }
}