import 'package:we_ticket/features/auth/data/auth_service.dart';
import 'package:we_ticket/features/mypage/data/my_ticket_service.dart';
import 'package:we_ticket/features/mypage/data/payment_history_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/contents/data/performance_service.dart';
import '../../../features/ticketing/data/services/ticket_service.dart';
import '../../../features/transfer/data/transfer_service.dart';

/// [ 모든 API 서비스를 통합 관리하는 클래스 ]
/// 앱 전체에서 하나의 인스턴스로 모든 API를 관리
/// DioClient를 공유하여 네트워크 설정을 일관되게 유지
class ApiService {
  final DioClient _dioClient;

  late final AuthService auth;
  late final PerformanceService performance;
  late final TicketService ticket;
  late final TransferService transfer;
  late final MyTicketService myTicket;

  /// 생성자
  ApiService(this._dioClient) {
    auth = AuthService(_dioClient);
    performance = PerformanceService(_dioClient);
    ticket = TicketService(_dioClient);
    transfer = TransferService(_dioClient);
    myTicket = MyTicketService(_dioClient);
  }

  /// 팩토리 생성자 - 기본 설정으로 생성
  factory ApiService.create() {
    return ApiService(DioClient());
  }

  /// 커스텀 DioClient로 생성
  factory ApiService.withCustomClient(DioClient dioClient) {
    return ApiService(dioClient);
  }

  /// 네트워크 연결 상태 확인
  /// 실제 API 호출 전에 기본적인 연결 상태를 확인
  Future<bool> checkConnection() async {
    try {
      print('네트워크 연결 상태 확인 중...');

      // 가장 가벼운 API 호출로 연결 상태 확인
      final result = await performance.getHotPerformances();

      if (!result.isSuccess) {
        throw Exception(result.errorMessage ?? '네트워크 연결 실패');
      }

      print('✅ 네트워크 연결 정상');
      return true;
    } catch (e) {
      print('❌ 네트워크 연결 실패: $e');
      return false;
    }
  }

  /// 모든 대시보드 데이터를 한 번에 로드
  Future<Map<String, dynamic>> loadDashboardData() async {
    try {
      // HOT 공연, 예매 가능한 공연
      final results = await Future.wait([
        performance.getHotPerformances(),
        performance.getAvailablePerformances(),
      ]);

      // ApiResult 체크
      if (!results[0].isSuccess || !results[1].isSuccess) {
        throw Exception('대시보드 데이터 로딩 실패');
      }

      final dashboardData = {
        'hotPerformances': results[0].data!,
        'availablePerformances': results[1].data!,
        'loadedAt': DateTime.now(),
      };

      print('✅ 대시보드 데이터 로딩 완료');
      return dashboardData;
    } catch (e) {
      print('❌ 대시보드 데이터 로딩 실패: $e');
      rethrow;
    }
  }

  /// 양도 마켓 대시보드 데이터 로드
  /// 양도 마켓 메인 화면에서 필요한 데이터를 로드
  Future<Map<String, dynamic>> loadTransferMarketData() async {
    try {
      // 양도 가능한 티켓 리스트 조회
      final result = await transfer.getTransferTicketList();

      if (!result.isSuccess) {
        throw Exception(result.errorMessage ?? '양도 마켓 데이터 로딩 실패');
      }

      final transferList = result.data!;

      final transferMarketData = {
        'transferTickets': transferList.results,
        'totalCount': transferList.count,
        'loadedAt': DateTime.now(),
      };

      print('✅ 양도 마켓 데이터 로딩 완료 (${transferList.results.length}개)');
      return transferMarketData;
    } catch (e) {
      print('❌ 양도 마켓 데이터 로딩 실패: $e');
      rethrow;
    }
  }

  /// 사용자별 양도 관리 데이터 로드
  ///
  /// 내 양도 등록 티켓과 양도 가능한 티켓을 동시에 로드합니다.
  Future<Map<String, dynamic>> loadUserTransferData(int userId) async {
    try {
      print('👤 사용자 양도 데이터 로딩 시작 (사용자 ID: $userId)');

      // 내 양도 등록 티켓과 양도 가능한 티켓을 동시에 요청
      final results = await Future.wait([
        transfer.getMyRegisteredTickets(userId: userId),
        transfer.getMyTransferableTickets(userId: userId),
      ]);

      // ApiResult 체크
      if (!results[0].isSuccess || !results[1].isSuccess) {
        throw Exception('양도 데이터 로딩 실패');
      }

      final userTransferData = {
        'registeredTickets': results[0].data!,
        'transferableTickets': results[1].data!,
        'loadedAt': DateTime.now(),
      };

      print('✅ 사용자 양도 데이터 로딩 완료');
      return userTransferData;
    } catch (e) {
      print('❌ 사용자 양도 데이터 로딩 실패: $e');
      rethrow;
    }
  }

  /// 내 티켓 목록 조회
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
        '/tickets/my-page/owned-ticket-list/',
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
        '/tickets/my-ticket-detail/',
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

  /// 사용자별 티켓 관리 데이터 로드
  ///
  /// 내 티켓 목록과 구매 이력을 동시에 로드합니다.
  Future<Map<String, dynamic>> loadUserTicketData(int userId) async {
    try {
      print('🎫 사용자 티켓 데이터 로딩 시작 (사용자 ID: $userId)');

      // 내 티켓 목록과 구매 이력을 동시에 요청
      final results = await Future.wait([
        myTicket.getOwnedTickets(userId),
        myTicket.getTouchedTickets(userId),
      ]);

      final userTicketData = {
        'ownedTickets': results[0],
        'purchaseHistory': results[1],
        'loadedAt': DateTime.now(),
      };

      print('✅ 사용자 티켓 데이터 로딩 완료');
      return userTicketData;
    } catch (e) {
      print('❌ 사용자 티켓 데이터 로딩 실패: $e');
      rethrow;
    }
  }

  /// 전체 예매 플로우 데이터 로드
  ///
  /// 예매에 필요한 모든 정보를 순차적으로 가져옵니다.
  Future<Map<String, dynamic>> loadBookingFlow(int performanceId) async {
    try {
      print('🎫 예매 플로우 데이터 로딩 시작 (공연 ID: $performanceId)');

      // 1. 공연 상세 정보
      final performanceDetailResult = await performance.getPerformanceDetail(
        performanceId,
      );

      if (!performanceDetailResult.isSuccess) {
        throw Exception(
          performanceDetailResult.errorMessage ?? '공연 상세 정보 로딩 실패',
        );
      }

      final performanceDetail = performanceDetailResult.data!;

      // 2. 공연 스케줄
      final scheduleResult = await ticket.getPerformanceSchedule(performanceId);

      if (!scheduleResult.isSuccess) {
        throw Exception(scheduleResult.errorMessage ?? '공연 스케줄 로딩 실패');
      }

      final schedule = scheduleResult.data!;

      // 3. 첫 번째 세션의 좌석 정보 (미리 로드)
      final availableSessions = schedule.sessions;
      Map<String, dynamic>? firstSessionData;

      if (availableSessions.isNotEmpty) {
        final firstSession = availableSessions.first;
        final seatInfoResult = await ticket.getSessionSeatInfo(
          performanceId,
          firstSession.performanceSessionId,
        );

        if (seatInfoResult.isSuccess) {
          firstSessionData = {
            'session': firstSession,
            'seatInfo': seatInfoResult.data!,
          };
        }
      }

      final bookingData = {
        'performanceDetail': performanceDetail,
        'schedule': schedule,
        'firstSessionData': firstSessionData,
        'canBook': performanceDetail.canBook && availableSessions.isNotEmpty,
        'loadedAt': DateTime.now(),
      };

      print('✅ 예매 플로우 데이터 로딩 완료');
      return bookingData;
    } catch (e) {
      print('❌ 예매 플로우 데이터 로딩 실패: $e');
      rethrow;
    }
  }

  /// 로그인 후 필요한 초기 데이터 로드
  ///
  /// 로그인 성공 후 사용자별 데이터를 미리 가져옵니다.
  Future<Map<String, dynamic>> loadUserInitialData(int userId) async {
    try {
      print('👤 사용자 초기 데이터 로딩 시작 (사용자 ID: $userId)');

      // 대시보드 데이터, 양도 데이터, 티켓 데이터를 동시에 로드
      final results = await Future.wait([
        loadDashboardData(),
        loadUserTransferData(userId),
        loadUserTicketData(userId),
      ]);

      final initialData = {
        'userId': userId,
        'dashboardData': results[0],
        'transferData': results[1],
        'ticketData': results[2],
        'loginTime': DateTime.now(),
      };

      print('✅ 사용자 초기 데이터 로딩 완료');
      return initialData;
    } catch (e) {
      print('❌ 사용자 초기 데이터 로딩 실패: $e');
      rethrow;
    }
  }

  // ApiService 클래스에 추가할 메서드들

  /// 사용자별 결제 이력 데이터 로드
  ///
  /// 결제 이력과 기본 사용자 정보를 동시에 로드합니다.
  Future<Map<String, dynamic>> loadUserPaymentData(
    int userId, {
    String? filter,
  }) async {
    try {
      print('💳 사용자 결제 데이터 로딩 시작 (사용자 ID: $userId, 필터: $filter)');

      // 필터별 결제 이력 조회
      final paymentHistories = await myTicket.getFilteredPaymentHistory(
        userId,
        filter ?? '전체 거래',
      );

      final paymentData = {
        'userId': userId,
        'filter': filter ?? '전체 거래',
        'paymentHistories': paymentHistories,
        // 'totalCount': paymentHistories.length,
        'loadedAt': DateTime.now(),
      };

      // print('✅ 사용자 결제 데이터 로딩 완료 (${paymentHistories.length}개)');
      return paymentData;
    } catch (e) {
      print('❌ 사용자 결제 데이터 로딩 실패: $e');
      rethrow;
    }
  }

  /// 결제 이력 통계 데이터 생성
  ///
  /// 결제 이력을 바탕으로 통계 정보를 생성합니다.
  Map<String, dynamic> generatePaymentStatistics(
    List<PaymentHistory> histories,
  ) {
    try {
      print('📊 결제 이력 통계 생성 시작');

      final stats = {
        'totalCount': histories.length,
        'purchaseCount': histories
            .where((h) => h.isPurchase || h.isTransferBuy)
            .length,
        'sellCount': histories.where((h) => h.isTransferSell).length,
        'cancelCount': histories.where((h) => h.isCancel).length,
        'completedCount': histories.where((h) => h.isCompleted).length,
        'pendingCount': histories.where((h) => h.isPending).length,
        'totalAmount': histories.fold<int>(0, (sum, h) => sum + h.price),
        'averageAmount': histories.isEmpty
            ? 0
            : histories.fold<int>(0, (sum, h) => sum + h.price) ~/
                  histories.length,
        'lastPaymentDate': histories.isEmpty
            ? null
            : histories
                  .map((h) => h.paymentDate)
                  .reduce((a, b) => a.isAfter(b) ? a : b),
        'generatedAt': DateTime.now(),
      };

      print('✅ 결제 이력 통계 생성 완료');
      return stats;
    } catch (e) {
      print('❌ 결제 이력 통계 생성 실패: $e');
      return {
        'totalCount': 0,
        'error': e.toString(),
        'generatedAt': DateTime.now(),
      };
    }
  }

  /// API 서비스 상태 진단
  ///
  /// 각 서비스별로 간단한 호출을 통해 상태를 확인합니다.
  Future<Map<String, bool>> diagnoseServices() async {
    print('🔍 API 서비스 상태 진단 시작...');

    final results = <String, bool>{};

    // Performance Service 테스트
    try {
      final result = await performance.getHotPerformances();
      results['performance'] = result.isSuccess;
      if (result.isSuccess) {
        print('✅ Performance Service 정상');
      } else {
        print('❌ Performance Service 오류: ${result.errorMessage}');
      }
    } catch (e) {
      results['performance'] = false;
      print('❌ Performance Service 오류: $e');
    }

    // Transfer Service 테스트
    try {
      final result = await transfer.getTransferTicketList();
      results['transfer'] = result.isSuccess;
      if (result.isSuccess) {
        print('✅ Transfer Service 정상');
      } else {
        print('❌ Transfer Service 오류: ${result.errorMessage}');
      }
    } catch (e) {
      results['transfer'] = false;
      print('❌ Transfer Service 오류: $e');
    }

    // Auth Service 테스트 (로그인은 위험하므로 스킵)
    results['auth'] = true;
    print('⚠️ Auth Service 테스트 스킵 (실제 로그인 위험)');

    // MyTicket Service 테스트 (사용자 ID가 필요해서 스킵)
    results['myTicket'] = true;
    print('⚠️ MyTicket Service 테스트 스킵 (user_id 필요)');

    // Ticket Service 테스트 (스케줄 조회는 performance_id가 필요해서 스킵)
    results['ticket'] = true;
    print('⚠️ Ticket Service 테스트 스킵 (performance_id 필요)');

    print('🔍 API 서비스 상태 진단 완료');
    return results;
  }

  /// 전체 서비스 리셋
  ///
  /// 네트워크 오류 등으로 인해 전체 서비스를 재초기화해야 할 때 사용합니다.
  void resetServices() {
    print('🔄 API 서비스 리셋 중...');

    // 새로운 DioClient로 각 서비스 재생성
    auth = AuthService(_dioClient);
    performance = PerformanceService(_dioClient);
    ticket = TicketService(_dioClient);
    transfer = TransferService(_dioClient);
    myTicket = MyTicketService(_dioClient);

    print('✅ API 서비스 리셋 완료');
  }

  /// 리소스 정리
  ///
  /// 앱 종료 시 네트워크 리소스를 정리합니다.
  void dispose() {
    print('🗑️ ApiService 리소스 정리 중...');
    // DioClient의 리소스 정리는 DioClient 자체에서 처리
    print('✅ ApiService 리소스 정리 완료');
  }
}
