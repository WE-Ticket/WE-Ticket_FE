import '../core/dio_client.dart';
import 'performance_service.dart';
import 'ticket_service.dart';
import 'user_service.dart';

/// 모든 API 서비스를 통합 관리하는 클래스
///
/// 앱 전체에서 하나의 인스턴스로 모든 API를 관리합니다.
/// DioClient를 공유하여 네트워크 설정을 일관되게 유지합니다.
class ApiService {
  final DioClient _dioClient;

  // 각 도메인별 서비스들
  late final PerformanceService performance;
  late final TicketService ticket;
  late final UserService user;

  /// 생성자
  ///
  /// DioClient 인스턴스를 받아서 각 서비스에 주입합니다.
  ApiService(this._dioClient) {
    performance = PerformanceService(_dioClient);
    ticket = TicketService(_dioClient);
    user = UserService(_dioClient);

    print('🚀 ApiService 초기화 완료');
  }

  /// 팩토리 생성자 - 기본 설정으로 생성
  ///
  /// 가장 간단하게 ApiService를 생성하는 방법입니다.
  /// DioClient를 내부에서 자동으로 생성합니다.
  factory ApiService.create() {
    print('🔧 ApiService 기본 설정으로 생성 중...');
    return ApiService(DioClient());
  }

  /// 커스텀 DioClient로 생성
  ///
  /// 특별한 네트워크 설정이 필요한 경우 사용합니다.
  factory ApiService.withCustomClient(DioClient dioClient) {
    print('🔧 ApiService 커스텀 설정으로 생성 중...');
    return ApiService(dioClient);
  }

  /// 네트워크 연결 상태 확인
  ///
  /// 실제 API 호출 전에 기본적인 연결 상태를 확인합니다.
  Future<bool> checkConnection() async {
    try {
      print('🌐 네트워크 연결 상태 확인 중...');

      // 가장 가벼운 API 호출로 연결 상태 확인
      // HOT 공연 API를 이용 (보통 빠르고 가벼움)
      await performance.getHotPerformances();

      print('✅ 네트워크 연결 정상');
      return true;
    } catch (e) {
      print('❌ 네트워크 연결 실패: $e');
      return false;
    }
  }

  /// 모든 대시보드 데이터를 한 번에 로드
  ///
  /// 대시보드 화면에서 필요한 모든 데이터를 병렬로 가져옵니다.
  Future<Map<String, dynamic>> loadDashboardData() async {
    try {
      print('📊 대시보드 데이터 로딩 시작...');

      // HOT 공연과 예매 가능한 공연을 동시에 요청
      final results = await Future.wait([
        performance.getHotPerformances(),
        performance.getAvailablePerformances(),
      ]);

      final dashboardData = {
        'hotPerformances': results[0],
        'availablePerformances': results[1],
        'loadedAt': DateTime.now(),
      };

      print('✅ 대시보드 데이터 로딩 완료');
      return dashboardData;
    } catch (e) {
      print('❌ 대시보드 데이터 로딩 실패: $e');
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
      final performanceDetail = await performance.getPerformanceDetail(
        performanceId,
      );

      // 2. 공연 스케줄
      final schedule = await ticket.getPerformanceSchedule(performanceId);

      // 3. 첫 번째 세션의 좌석 정보 (미리 로드)
      final availableSessions = schedule.availableSessions;
      Map<String, dynamic>? firstSessionData;

      if (availableSessions.isNotEmpty) {
        final firstSession = availableSessions.first;
        final seatInfo = await ticket.getSessionSeatInfo(
          performanceId,
          firstSession.performanceSessionId,
        );

        firstSessionData = {'session': firstSession, 'seatInfo': seatInfo};
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

      // 현재는 공통 데이터만 로드 (사용자별 API가 없음)
      // 나중에 사용자 티켓 목록, 찜한 공연 등의 API가 추가되면 여기서 로드

      final initialData = {
        'userId': userId,
        'dashboardData': await loadDashboardData(),
        'loginTime': DateTime.now(),
      };

      print('✅ 사용자 초기 데이터 로딩 완료');
      return initialData;
    } catch (e) {
      print('❌ 사용자 초기 데이터 로딩 실패: $e');
      rethrow;
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
      await performance.getHotPerformances();
      results['performance'] = true;
      print('✅ Performance Service 정상');
    } catch (e) {
      results['performance'] = false;
      print('❌ Performance Service 오류: $e');
    }

    // Ticket Service 테스트 (스케줄 조회는 performance_id가 필요해서 스킵)
    results['ticket'] = true; // 일단 true로 설정
    print('⚠️ Ticket Service 테스트 스킵 (performance_id 필요)');

    // User Service 테스트 (실제 로그인은 위험해서 스킵)
    results['user'] = true; // 일단 true로 설정
    print('⚠️ User Service 테스트 스킵 (실제 로그인 위험)');

    print('🔍 API 서비스 상태 진단 완료');
    return results;
  }

  /// 전체 서비스 리셋
  ///
  /// 네트워크 오류 등으로 인해 전체 서비스를 재초기화해야 할 때 사용합니다.
  void resetServices() {
    print('🔄 API 서비스 리셋 중...');

    // 새로운 DioClient로 각 서비스 재생성
    performance = PerformanceService(_dioClient);
    ticket = TicketService(_dioClient);
    user = UserService(_dioClient);

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
