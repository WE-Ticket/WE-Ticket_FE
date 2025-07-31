import '../../../core/services/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';
import 'transfer_models.dart';

/// 양도 마켓 관련 API 서비스
class TransferService {
  final DioClient _dioClient;

  TransferService(this._dioClient);

  /// 양도 가능한 티켓 전체 리스트 조회 (공연 필터 가능)
  /// GET /api/transfers/ticket-list/?performance_id=공연아이디
  Future<TransferListResponse> getTransferTicketList({
    int? performanceId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🎫 양도 티켓 리스트 조회 시작');

      String endpoint = ApiConstants.transferTicketList;

      // 쿼리 파라미터 구성
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

      final response = await _dioClient.get(
        endpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final transferList = TransferListResponse.fromJson(response.data);
        print('✅ 양도 티켓 리스트 조회 성공 (${transferList.results.length}개)');
        return transferList;
      } else {
        throw Exception('양도 티켓 리스트 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 양도 티켓 리스트 조회 오류: $e');
      rethrow;
    }
  }

  /// 공개 티켓 상세 정보 조회
  /// GET /api/transfers/ticket-detail/{transfer_ticket_id}
  Future<TransferTicketDetail> getPublicTransferDetail(
    int transferTicketId,
  ) async {
    try {
      print('🔍 공개 양도 티켓 상세 조회 시작 (ID: $transferTicketId)');

      final endpoint = ApiConstants.transferTicketDetail.replaceAll(
        '{transfer_ticket_id}',
        transferTicketId.toString(),
      );

      final response = await _dioClient.get(endpoint);

      if (response.statusCode == 200) {
        final detail = TransferTicketDetail.fromJson(response.data);
        print('✅ 공개 양도 티켓 상세 조회 성공');
        return detail;
      } else {
        throw Exception('공개 양도 티켓 상세 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 공개 양도 티켓 상세 조회 오류 (ID: $transferTicketId): $e');
      rethrow;
    }
  }

  /// 고유번호 조회
  /// POST /api/transfers/unique-code-lookup/
  Future<TransferUniqueCode> getUniqueCode(int transferTicketId) async {
    try {
      print('🔑 고유번호 조회 시작 (티켓 ID: $transferTicketId)');

      final response = await _dioClient.post(
        ApiConstants.uniqueCodeLookup,
        data: {'transfer_ticket_id': transferTicketId},
      );

      if (response.statusCode == 200) {
        final uniqueCode = TransferUniqueCode.fromJson(response.data);
        print('✅ 고유번호 조회 성공: ${uniqueCode.tempUniqueCode}');
        return uniqueCode;
      } else {
        throw Exception('고유번호 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 고유번호 조회 오류 (티켓 ID: $transferTicketId): $e');
      rethrow;
    }
  }

  /// 고유번호 재발급
  /// POST /api/transfers/unique-code-regeneration/
  Future<TransferUniqueCode> regenerateUniqueCode(int transferTicketId) async {
    try {
      print('🔄 고유번호 재발급 시작 (티켓 ID: $transferTicketId)');

      final response = await _dioClient.post(
        ApiConstants.uniqueCodeRegeneration,
        data: {'transfer_ticket_id': transferTicketId},
      );

      if (response.statusCode == 200) {
        final uniqueCode = TransferUniqueCode.fromJson(response.data);
        print('✅ 고유번호 재발급 성공: ${uniqueCode.tempUniqueCode}');
        return uniqueCode;
      } else {
        throw Exception('고유번호 재발급 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 고유번호 재발급 오류 (티켓 ID: $transferTicketId): $e');
      rethrow;
    }
  }

  //고유 번호로 양도 티켓 id 조회
  Future<int> lookupPrivateTicket(String code) async {
    try {
      print('고유번호로 조회 시작 (티켓 ID: $code)');

      final response = await _dioClient.post(
        ApiConstants.lookupPrivateTicket,
        data: {"temp_unique_code": code},
      );

      if (response.statusCode == 200) {
        final result = response.data;
        print('비공개 티켓 id 조회: ${result["transfer_ticket_id"]}');
        return result["transfer_ticket_id"];
      } else {
        throw Exception('티켓 조회 실패');
      }
    } catch (e) {
      print('❌ 비공개 티켓 조회 오류: $e');
      rethrow;
    }
  }

  /// 양도 방식 변경 (공개/비공개 토글)
  /// POST /api/transfers/transfer-ticket-toggle-public/
  Future<Map<String, dynamic>> toggleTransferType(int transferTicketId) async {
    try {
      print('🔄 양도 방식 변경 시작 (티켓 ID: $transferTicketId)');

      final response = await _dioClient.post(
        ApiConstants.transferTicketTogglePublic,
        data: {'transfer_ticket_id': transferTicketId},
      );

      if (response.statusCode == 200) {
        print('✅ 양도 방식 변경 성공');
        return response.data;
      } else {
        throw Exception('양도 방식 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 양도 방식 변경 오류 (티켓 ID: $transferTicketId): $e');
      rethrow;
    }
  }

  /// 양도 취소
  /// POST /api/transfers/transfer-ticket-cancel/
  Future<Map<String, dynamic>> cancelTransfer(int transferTicketId) async {
    try {
      print('🚫 양도 취소 시작 (티켓 ID: $transferTicketId)');

      final response = await _dioClient.post(
        ApiConstants.transferTicketCancel,
        data: {'transfer_ticket_id': transferTicketId},
      );

      if (response.statusCode == 200) {
        print('✅ 양도 취소 성공');
        return response.data;
      } else {
        throw Exception('양도 취소 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 양도 취소 오류 (티켓 ID: $transferTicketId): $e');
      rethrow;
    }
  }

  /// 양도 등록한 티켓 리스트 조회 (기간 필터 가능)
  /// POST /api/transfers/my-ticket-list/registered/
  Future<List<MyTransferTicket>> getMyRegisteredTickets({
    required int userId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      print('📋 내 양도 등록 티켓 리스트 조회 시작 (사용자 ID: $userId)');

      final data = <String, dynamic>{'user_id': userId};
      if (startDate != null) data['start_date'] = startDate;
      if (endDate != null) data['end_date'] = endDate;

      final response = await _dioClient.post(
        ApiConstants.myRegisteredTickets,
        data: data,
      );

      if (response.statusCode == 200) {
        final List<dynamic> listData = response.data;
        final tickets = listData
            .map((json) => MyTransferTicket.fromJson(json))
            .toList();
        print('✅ 내 양도 등록 티켓 리스트 조회 성공 (${tickets.length}개)');
        return tickets;
      } else {
        throw Exception('내 양도 등록 티켓 리스트 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 내 양도 등록 티켓 리스트 조회 오류 (사용자 ID: $userId): $e');
      rethrow;
    }
  }

  /// 양도 가능한 티켓 리스트 조회 (기간 필터 가능)
  /// POST /api/transfers/my-ticket-list/transferable/
  Future<List<TransferableTicket>> getMyTransferableTickets({
    required int userId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      print('🎟️ 내 양도 가능 티켓 리스트 조회 시작 (사용자 ID: $userId)');

      final data = <String, dynamic>{'user_id': userId};
      if (startDate != null) data['start_date'] = startDate;
      if (endDate != null) data['end_date'] = endDate;

      final response = await _dioClient.post(
        ApiConstants.myTransferableTickets,
        data: data,
      );

      if (response.statusCode == 200) {
        final List<dynamic> listData = response.data;
        final tickets = listData
            .map((json) => TransferableTicket.fromJson(json))
            .toList();
        print('✅ 내 양도 가능 티켓 리스트 조회 성공 (${tickets.length}개)');
        return tickets;
      } else {
        throw Exception('내 양도 가능 티켓 리스트 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 내 양도 가능 티켓 리스트 조회 오류 (사용자 ID: $userId): $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> postTransferTicketRegister({
    required String ticketId,
    required bool isPublicTransfer,
    int? transferTicketPrice,
  }) async {
    try {
      final data = <String, dynamic>{
        'ticket_id': ticketId,
        "is_public_transfer": isPublicTransfer,
      };
      if (transferTicketPrice != null)
        data['transfer_ticket_price'] = transferTicketPrice;

      final response = await _dioClient.post(
        ApiConstants.transferTicketRegitster,
        data: data,
      );

      if (response.statusCode == 201) {
        print('✅ 양도 티켓 등록 완료');

        Map<String, dynamic> result = response.data;
        return result;
      } else {
        throw Exception('양도 티켓 등록 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 양도 티켓 등로 오류(티켓 ID: $ticketId): $e');
      rethrow;
    }
  }

  /// 공연별 양도 티켓 필터링 (로컬 처리)
  Future<List<TransferTicketItem>> getTransferTicketsByPerformance(
    int performanceId,
  ) async {
    try {
      print('🎯 공연별 양도 티켓 필터링 시작 (공연 ID: $performanceId)');

      final transferList = await getTransferTicketList(
        performanceId: performanceId,
      );

      print('✅ 공연별 양도 티켓 필터링 완료: ${transferList.results.length}개 결과');
      return transferList.results;
    } catch (e) {
      print('❌ 공연별 양도 티켓 필터링 오류: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> postProcessTransfer({
    required int userId,
    required int transferTicketId,
  }) async {
    try {
      print('📋 양도 진행 시작 (사용자 ID: $userId, 양도 티켓 ID : $transferTicketId)');

      final data = <String, dynamic>{
        "transfer_ticket_id": transferTicketId,
        "buyer_user_id": userId,
      };

      final response = await _dioClient.post(
        ApiConstants.processTransfer,
        data: data,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = response.data;

        print('✅ 양도 이행 성공');
        return result;
      } else {
        throw Exception('양도 이행  실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 양도 이행 오류 (사용자 ID: $userId): $e');
      rethrow;
    }
  }

  /// 날짜 범위별 양도 티켓 필터링 (API에서 지원하지 않아 로컬 처리)
  Future<List<TransferTicketItem>> getTransferTicketsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('📅 날짜 범위별 양도 티켓 필터링 시작');

      final transferList = await getTransferTicketList();

      final filteredResults = transferList.results.where((ticket) {
        final sessionDate = DateTime.parse(ticket.sessionDatetime);
        return sessionDate.isAfter(startDate.subtract(Duration(days: 1))) &&
            sessionDate.isBefore(endDate.add(Duration(days: 1)));
      }).toList();

      print('✅ 날짜 범위별 양도 티켓 필터링 완료: ${filteredResults.length}개 결과');
      return filteredResults;
    } catch (e) {
      print('❌ 날짜 범위별 양도 티켓 필터링 오류: $e');
      rethrow;
    }
  }

  /// 양도 티켓 검색 (제목, 아티스트명으로 검색 - 로컬 처리)
  Future<List<TransferTicketItem>> searchTransferTickets(String query) async {
    try {
      print('🔍 양도 티켓 검색 시작: "$query"');

      final transferList = await getTransferTicketList();

      final filteredResults = transferList.results.where((ticket) {
        final searchQuery = query.toLowerCase();
        return ticket.performanceTitle.toLowerCase().contains(searchQuery) ||
            ticket.performerName.toLowerCase().contains(searchQuery);
      }).toList();

      print('✅ 양도 티켓 검색 완료: ${filteredResults.length}개 결과');
      return filteredResults;
    } catch (e) {
      print('❌ 양도 티켓 검색 오류: $e');
      rethrow;
    }
  }
}
