import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_result.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/mixins/api_error_handler_mixin.dart';
import 'transfer_models.dart';

/// 양도 마켓 관련 API 서비스
class TransferService with ApiErrorHandlerMixin {
  final DioClient _dioClient;

  TransferService(this._dioClient);

  /// 양도 가능한 티켓 전체 리스트 조회 (공연 필터 가능)
  /// GET /api/transfers/ticket-list/?performance_id=공연아이디
  Future<ApiResult<TransferListResponse>> getTransferTicketList({
    int? performanceId,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.info('양도 티켓 리스트 조회 시작', 'TRANSFER');

    final queryParams = <String, dynamic>{};
    if (performanceId != null) {
      queryParams['performance_id'] = performanceId;
    }
    if (page > 1) {
      queryParams['page'] = page;
    }
    if (limit != 20) {
      queryParams['limit'] = limit;
    }

    return await _dioClient.getResult<TransferListResponse>(
      ApiConstants.transferTicketList,
      queryParameters: queryParams,
      parser: (data) {
        final transferList = TransferListResponse.fromJson(data);
        AppLogger.success(
          '양도 티켓 리스트 조회 성공 (${transferList.results.length}개)',
          'TRANSFER',
        );
        return transferList;
      },
    );
  }

  /// 공개 티켓 상세 정보 조회
  /// GET /api/transfers/ticket-detail/{transfer_ticket_id}
  Future<ApiResult<TransferTicketDetail>> getPublicTransferDetail(
    int transferTicketId,
  ) async {
    AppLogger.info('공개 양도 티켓 상세 조회 시작 (ID: $transferTicketId)', 'TRANSFER');

    final endpoint = ApiConstants.transferTicketDetail.replaceAll(
      '{transfer_ticket_id}',
      transferTicketId.toString(),
    );

    return await _dioClient.getResult<TransferTicketDetail>(
      endpoint,
      parser: (data) {
        final detail = TransferTicketDetail.fromJson(data);
        AppLogger.success('공개 양도 티켓 상세 조회 성공', 'TRANSFER');
        return detail;
      },
    );
  }

  /// 고유번호 조회
  /// POST /api/transfers/unique-code-lookup/
  Future<ApiResult<TransferUniqueCode>> getUniqueCode(
    int transferTicketId,
  ) async {
    AppLogger.info('고유번호 조회 시작 (티켓 ID: $transferTicketId)', 'TRANSFER');

    return await _dioClient.postResult<TransferUniqueCode>(
      ApiConstants.uniqueCodeLookup,
      data: {'transfer_ticket_id': transferTicketId},
      parser: (data) {
        final uniqueCode = TransferUniqueCode.fromJson(data);
        AppLogger.success(
          '고유번호 조회 성공: ${uniqueCode.tempUniqueCode}',
          'TRANSFER',
        );
        return uniqueCode;
      },
    );
  }

  /// 고유번호 재발급
  /// POST /api/transfers/unique-code-regeneration/
  Future<ApiResult<TransferUniqueCode>> regenerateUniqueCode(
    int transferTicketId,
  ) async {
    AppLogger.info('고유번호 재발급 시작 (티켓 ID: $transferTicketId)', 'TRANSFER');

    return await _dioClient.postResult<TransferUniqueCode>(
      ApiConstants.uniqueCodeRegeneration,
      data: {'transfer_ticket_id': transferTicketId},
      parser: (data) {
        final uniqueCode = TransferUniqueCode.fromJson(data);
        AppLogger.success(
          '고유번호 재발급 성공: ${uniqueCode.tempUniqueCode}',
          'TRANSFER',
        );
        return uniqueCode;
      },
    );
  }

  /// 고유 번호로 양도 티켓 id 조회
  /// POST /api/transfers/lookup-private-ticket/
  Future<ApiResult<int>> lookupPrivateTicket(String code) async {
    AppLogger.info('고유번호로 조회 시작 (코드: $code)', 'TRANSFER');

    return await _dioClient.postResult<int>(
      ApiConstants.lookupPrivateTicket,
      data: {"temp_unique_code": code},
      parser: (data) {
        final result = data as Map<String, dynamic>;
        final transferTicketId = result["transfer_ticket_id"] as int;
        AppLogger.success('비공개 티켓 id 조회 성공: $transferTicketId', 'TRANSFER');
        return transferTicketId;
      },
    );
  }

  /// 양도 방식 변경 (공개/비공개 토글)
  /// POST /api/transfers/transfer-ticket-toggle-public/
  Future<ApiResult<Map<String, dynamic>>> toggleTransferType(
    int transferTicketId,
  ) async {
    AppLogger.info('양도 방식 변경 시작 (티켓 ID: $transferTicketId)', 'TRANSFER');

    return await _dioClient.postResult<Map<String, dynamic>>(
      ApiConstants.transferTicketTogglePublic,
      data: {'transfer_ticket_id': transferTicketId},
      parser: (data) {
        AppLogger.success('양도 방식 변경 성공', 'TRANSFER');
        return data as Map<String, dynamic>;
      },
    );
  }

  /// 양도 취소
  /// POST /api/transfers/transfer-ticket-cancel/
  Future<ApiResult<Map<String, dynamic>>> cancelTransfer(
    int transferTicketId,
  ) async {
    AppLogger.info('양도 취소 시작 (티켓 ID: $transferTicketId)', 'TRANSFER');

    return await _dioClient.postResult<Map<String, dynamic>>(
      ApiConstants.transferTicketCancel,
      data: {'transfer_ticket_id': transferTicketId},
      parser: (data) {
        AppLogger.success('양도 취소 성공', 'TRANSFER');
        return data as Map<String, dynamic>;
      },
    );
  }

  /// 양도 등록한 티켓 리스트 조회 (기간 필터 가능)
  /// POST /api/transfers/my-ticket-list/registered/
  Future<ApiResult<List<MyTransferTicket>>> getMyRegisteredTickets({
    required int userId,
    String? startDate,
    String? endDate,
  }) async {
    AppLogger.info('내 양도 등록 티켓 리스트 조회 시작 (사용자 ID: $userId)', 'TRANSFER');

    final data = <String, dynamic>{'user_id': userId};
    if (startDate != null) data['start_date'] = startDate;
    if (endDate != null) data['end_date'] = endDate;

    return await _dioClient.postResult<List<MyTransferTicket>>(
      ApiConstants.myRegisteredTickets,
      data: data,
      parser: (data) {
        final List<dynamic> listData = data as List<dynamic>;
        final tickets = listData
            .map((json) => MyTransferTicket.fromJson(json))
            .toList();
        AppLogger.success(
          '내 양도 등록 티켓 리스트 조회 성공 (${tickets.length}개)',
          'TRANSFER',
        );
        return tickets;
      },
    );
  }

  /// 양도 가능한 티켓 리스트 조회 (기간 필터 가능)
  /// POST /api/transfers/my-ticket-list/transferable/
  Future<ApiResult<List<TransferableTicket>>> getMyTransferableTickets({
    required int userId,
    String? startDate,
    String? endDate,
  }) async {
    AppLogger.info('내 양도 가능 티켓 리스트 조회 시작 (사용자 ID: $userId)', 'TRANSFER');

    final data = <String, dynamic>{'user_id': userId};
    if (startDate != null) data['start_date'] = startDate;
    if (endDate != null) data['end_date'] = endDate;

    return await _dioClient.postResult<List<TransferableTicket>>(
      ApiConstants.myTransferableTickets,
      data: data,
      parser: (data) {
        final List<dynamic> listData = data as List<dynamic>;
        final tickets = listData
            .map((json) => TransferableTicket.fromJson(json))
            .toList();
        AppLogger.success(
          '내 양도 가능 티켓 리스트 조회 성공 (${tickets.length}개)',
          'TRANSFER',
        );
        return tickets;
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> postTransferTicketRegister({
    required userId,
    required String ticketId,
    required bool isPublicTransfer,
    int? transferTicketPrice,
  }) async {
    AppLogger.info('양도 티켓 등록 시작 (티켓 ID: $ticketId)', 'TRANSFER');

    final data = <String, dynamic>{
      'user_id': userId,
      'ticket_id': ticketId,
      'is_public_transfer': isPublicTransfer,
    };
    if (transferTicketPrice != null) {
      data['transfer_ticket_price'] = transferTicketPrice;
    }

    return await _dioClient.postResult<Map<String, dynamic>>(
      ApiConstants.transferTicketRegitster,
      data: data,
      parser: (data) {
        AppLogger.success('양도 티켓 등록 완료', 'TRANSFER');
        return data as Map<String, dynamic>;
      },
    );
  }

  /// 공연별 양도 티켓 필터링 (로컬 처리)
  Future<Either<Failure, List<TransferTicketItem>>>
  getTransferTicketsByPerformance(int performanceId) async {
    AppLogger.info('공연별 양도 티켓 필터링 시작 (공연 ID: $performanceId)', 'TRANSFER');

    final transferListResult = await getTransferTicketList(
      performanceId: performanceId,
    );

    if (transferListResult.isSuccess && transferListResult.data != null) {
      final transferList = transferListResult.data!;
      AppLogger.success(
        '공연별 양도 티켓 필터링 완료: ${transferList.results.length}개 결과',
        'TRANSFER',
      );
      return Right(transferList.results);
    } else {
      AppLogger.error(
        '공연별 양도 티켓 필터링 실패',
        transferListResult.errorMessage,
        null,
        'TRANSFER',
      );
      return Left(
        ServerFailure(
          message: transferListResult.errorMessage ?? '알 수 없는 오류가 발생했습니다',
        ),
      );
    }
  }

  /// 양도 이행 처리
  /// POST /api/transfers/process-transfer/
  Future<ApiResult<Map<String, dynamic>>> postProcessTransfer({
    required int userId,
    required int transferTicketId,
  }) async {
    AppLogger.info(
      '양도 진행 시작 (사용자 ID: $userId, 양도 티켓 ID: $transferTicketId)',
      'TRANSFER',
    );

    final data = <String, dynamic>{
      "transfer_ticket_id": transferTicketId,
      "buyer_user_id": userId,
    };

    return await _dioClient.postResult<Map<String, dynamic>>(
      ApiConstants.processTransfer,
      data: data,
      parser: (data) {
        final result = data as Map<String, dynamic>;
        AppLogger.success('양도 이행 성공', 'TRANSFER');
        return result;
      },
    );
  }

  /// 날짜 범위별 양도 티켓 필터링 (API에서 지원하지 않아 로컬 처리)
  Future<Either<Failure, List<TransferTicketItem>>>
  getTransferTicketsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    AppLogger.info('날짜 범위별 양도 티켓 필터링 시작', 'TRANSFER');

    final transferListResult = await getTransferTicketList();

    if (transferListResult.isSuccess && transferListResult.data != null) {
      final transferList = transferListResult.data!;
      final filteredResults = transferList.results.where((ticket) {
        final sessionDate = DateTime.parse(ticket.sessionDatetime);
        return sessionDate.isAfter(startDate.subtract(Duration(days: 1))) &&
            sessionDate.isBefore(endDate.add(Duration(days: 1)));
      }).toList();

      AppLogger.success(
        '날짜 범위별 양도 티켓 필터링 완료: ${filteredResults.length}개 결과',
        'TRANSFER',
      );
      return Right(filteredResults);
    } else {
      AppLogger.error(
        '날짜 범위별 양도 티켓 필터링 실패',
        transferListResult.errorMessage,
        null,
        'TRANSFER',
      );
      return Left(
        ServerFailure(
          message: transferListResult.errorMessage ?? '알 수 없는 오류가 발생했습니다',
        ),
      );
    }
  }

  /// 양도 티켓 검색 (제목, 아티스트명으로 검색 - 로컬 처리)
  Future<Either<Failure, List<TransferTicketItem>>> searchTransferTickets(
    String query,
  ) async {
    AppLogger.info('양도 티켓 검색 시작: "$query"', 'TRANSFER');

    final transferListResult = await getTransferTicketList();

    if (transferListResult.isSuccess && transferListResult.data != null) {
      final transferList = transferListResult.data!;
      final filteredResults = transferList.results.where((ticket) {
        final searchQuery = query.toLowerCase();
        return ticket.performanceTitle.toLowerCase().contains(searchQuery) ||
            ticket.performerName.toLowerCase().contains(searchQuery);
      }).toList();

      AppLogger.success(
        '양도 티켓 검색 완료: ${filteredResults.length}개 결과',
        'TRANSFER',
      );
      return Right(filteredResults);
    } else {
      AppLogger.error(
        '양도 티켓 검색 실패',
        transferListResult.errorMessage,
        null,
        'TRANSFER',
      );
      return Left(
        ServerFailure(
          message: transferListResult.errorMessage ?? '알 수 없는 오류가 발생했습니다',
        ),
      );
    }
  }
}
