import '../../../../core/services/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/performance_models.dart';

class PerformanceService {
  final DioClient _dioClient;

  PerformanceService(this._dioClient);

  /// HOT 공연 3개 조회
  /// GET /performances/hot/
  Future<List<PerformanceHotItem>> getHotPerformances() async {
    try {
      final response = await _dioClient.get(ApiConstants.hotPerformances);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final performances = data
            .map((json) => PerformanceHotItem.fromJson(json))
            .toList();
        print('✅ HOT 공연 ${performances.length}개 조회 성공');
        return performances;
      } else {
        throw Exception('HOT 공연 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ HOT 공연 조회 오류: $e');
      rethrow;
    }
  }

  /// 예매 가능한 공연 5개 조회
  /// GET /performances/available/
  /// 대시보드 "예매 가능한 공연" 섹션에서 사용
  Future<List<PerformanceAvailableItem>> getAvailablePerformances() async {
    try {
      print('!!! 예매 가능한 공연 조회 시작');
      final response = await _dioClient.get(ApiConstants.availablePerformances);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final performances = data
            .map((json) => PerformanceAvailableItem.fromJson(json))
            .toList();
        print('✅ 예매 가능한 공연 ${performances.length}개 조회 성공');
        return performances;
      } else {
        throw Exception('예매 가능한 공연 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 예매 가능한 공연 조회 오류: $e');
      rethrow;
    }
  }

  /// 전체 공연 목록 조회 (페이지네이션 포함)
  /// GET /performances/list/
  /// 공연 목록 페이지에서 사용
  Future<PerformanceListResponse> getAllPerformances({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('📋 전체 공연 목록 조회 시작 (페이지: $page)');

      String endpoint = ApiConstants.performancesList;
      if (page > 1) {
        endpoint += '?page=$page&limit=$limit';
      }

      final response = await _dioClient.get(endpoint);

      if (response.statusCode == 200) {
        final performanceList = PerformanceListResponse.fromJson(response.data);
        print(
          '✅ 전체 공연 목록 조회 성공 (총 ${performanceList.count}개, 현재 페이지 ${performanceList.results.length}개)',
        );
        return performanceList;
      } else {
        throw Exception('전체 공연 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 전체 공연 목록 조회 오류: $e');
      rethrow;
    }
  }

  /// 공연 상세 정보 조회
  /// GET /performances/{performance_id}/
  /// 공연 상세 페이지에서 사용
  Future<PerformanceDetail> getPerformanceDetail(int performanceId) async {
    try {
      print('!!! 공연 상세 정보 조회 시작 (ID: $performanceId)');
      final endpoint = ApiConstants.performanceDetail.replaceAll(
        '{performance_id}',
        performanceId.toString(),
      );
      final response = await _dioClient.get(endpoint);

      if (response.statusCode == 200) {
        final performance = PerformanceDetail.fromJson(response.data);
        print('✅ 공연 상세 정보 조회 성공: ${performance.title}');
        return performance;
      } else {
        throw Exception('공연 상세 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 공연 상세 정보 조회 오류 (ID: $performanceId): $e');
      rethrow;
    }
  }

  ///FIXME API는 있지만, 일단은 프론트에서 하고, 추후 api연결로 전환
  /// 장르별 공연 필터링
  Future<List<PerformanceListItem>> getPerformancesByGenre(String genre) async {
    try {
      print('!!! 장르별 공연 조회 시작: $genre');

      final allPerformances = await getAllPerformances();
      final filteredResults = allPerformances.results.where((performance) {
        return performance.genre.toLowerCase() == genre.toLowerCase();
      }).toList();

      print('✅ 장르별 공연 조회 완료: ${filteredResults.length}개 결과');
      return filteredResults;
    } catch (e) {
      print('❌ 장르별 공연 조회 오류: $e');
      rethrow;
    }
  }
}
