import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/app_logger.dart';
import 'performance_models.dart';

class PerformanceService {
  final DioClient _dioClient;

  PerformanceService(this._dioClient);

  /// HOT 공연 3개 조회
  /// GET /performances/hot/
  Future<ApiResult<List<PerformanceHotItem>>> getHotPerformances() async {
    return await _dioClient.getResult<List<PerformanceHotItem>>(
      ApiConstants.hotPerformances,
      parser: (data) {
        final List<dynamic> listData = data;
        final performances = listData
            .map((json) => PerformanceHotItem.fromJson(json))
            .toList();
        AppLogger.success('HOT 공연 ${performances.length}개 조회 성공', 'PERFORMANCE');
        return performances;
      },
    );
  }

  /// 예매 가능한 공연 5개 조회
  /// GET /performances/available/
  /// 대시보드 "예매 가능한 공연" 섹션에서 사용
  Future<ApiResult<List<PerformanceAvailableItem>>> getAvailablePerformances() async {
    AppLogger.info('예매 가능한 공연 조회 시작', 'PERFORMANCE');
    
    return await _dioClient.getResult<List<PerformanceAvailableItem>>(
      ApiConstants.availablePerformances,
      parser: (data) {
        final List<dynamic> listData = data;
        final performances = listData
            .map((json) => PerformanceAvailableItem.fromJson(json))
            .toList();
        AppLogger.success('예매 가능한 공연 ${performances.length}개 조회 성공', 'PERFORMANCE');
        return performances;
      },
    );
  }

  /// 전체 공연 목록 조회 (페이지네이션 포함)
  /// GET /performances/list/
  /// 공연 목록 페이지에서 사용
  Future<ApiResult<PerformanceListResponse>> getAllPerformances({
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.info('전체 공연 목록 조회 시작 (페이지: $page)', 'PERFORMANCE');

    final queryParams = <String, dynamic>{};
    if (page > 1) {
      queryParams['page'] = page;
      queryParams['limit'] = limit;
    }

    return await _dioClient.getResult<PerformanceListResponse>(
      ApiConstants.performancesList,
      queryParameters: queryParams,
      parser: (data) {
        final performanceList = PerformanceListResponse.fromJson(data);
        AppLogger.success(
          '전체 공연 목록 조회 성공 (총 ${performanceList.count}개, 현재 페이지 ${performanceList.results.length}개)',
          'PERFORMANCE',
        );
        return performanceList;
      },
    );
  }

  /// 공연 상세 정보 조회
  /// GET /performances/{performance_id}/
  /// 공연 상세 페이지에서 사용
  Future<ApiResult<PerformanceDetail>> getPerformanceDetail(int performanceId) async {
    AppLogger.info('공연 상세 정보 조회 시작 (ID: $performanceId)', 'PERFORMANCE');
    
    final endpoint = ApiConstants.performanceDetail.replaceAll(
      '{performance_id}',
      performanceId.toString(),
    );

    return await _dioClient.getResult<PerformanceDetail>(
      endpoint,
      parser: (data) {
        final performance = PerformanceDetail.fromJson(data);
        AppLogger.success('공연 상세 정보 조회 성공: ${performance.title}', 'PERFORMANCE');
        return performance;
      },
    );
  }

  ///FIXME API는 있지만, 일단은 프론트에서 하고, 추후 api연결로 전환
  /// 장르별 공연 필터링
  Future<ApiResult<List<PerformanceListItem>>> getPerformancesByGenre(String genre) async {
    AppLogger.info('장르별 공연 조회 시작: $genre', 'PERFORMANCE');

    final allPerformancesResult = await getAllPerformances();
    
    if (!allPerformancesResult.isSuccess) {
      return ApiResult.failure(
        allPerformancesResult.errorMessage ?? '전체 공연 목록 조회 실패',
        errorType: allPerformancesResult.errorType,
        statusCode: allPerformancesResult.statusCode,
      );
    }

    final allPerformances = allPerformancesResult.data!;
    final filteredResults = allPerformances.results.where((performance) {
      return performance.genre.toLowerCase() == genre.toLowerCase();
    }).toList();

    AppLogger.success('장르별 공연 조회 완료: ${filteredResults.length}개 결과', 'PERFORMANCE');
    return ApiResult.success(filteredResults);
  }
}
