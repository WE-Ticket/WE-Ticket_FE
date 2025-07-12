import '../core/dio_client.dart';
import '../core/api_constants.dart';
import '../models/performance_model.dart';

class PerformanceService {
  final DioClient _dioClient;

  PerformanceService(this._dioClient);

  // 예매 가능한 공연 5개 조회
  Future<List<PerformanceModel>> getAvailablePerformances() async {
    try {
      final response = await _dioClient.get(ApiConstants.availablePerformances);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PerformanceModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load available performances');
      }
    } catch (e) {
      print('Error in getAvailablePerformances: $e');
      rethrow;
    }
  }

  // 핫한 공연 3개 조회
  Future<List<PerformanceModel>> getHotPerformances() async {
    try {
      final response = await _dioClient.get(ApiConstants.hotPerformances);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PerformanceModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load hot performances');
      }
    } catch (e) {
      print('Error in getHotPerformances: $e');
      rethrow;
    }
  }

  // 전체 공연 목록 조회 (페이지네이션)
  Future<Map<String, dynamic>> getAllPerformances() async {
    try {
      final response = await _dioClient.get(ApiConstants.performancesList);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load all performances');
      }
    } catch (e) {
      print('Error in getAllPerformances: $e');
      rethrow;
    }
  }

  // 공연 상세 정보 조회
  Future<PerformanceModel> getPerformanceDetail(int performanceId) async {
    try {
      final endpoint = ApiConstants.performanceDetail.replaceAll(
        '{performance_id}',
        performanceId.toString(),
      );
      print(endpoint);
      final response = await _dioClient.get(endpoint);
      print(response);
      print(response.statusCode);

      if (response.statusCode == 200) {
        return PerformanceModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load performance detail');
      }
    } catch (e) {
      print('Error in getPerformanceDetail: $e');
      rethrow;
    }
  }
}
