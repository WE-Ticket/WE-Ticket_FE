import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/mixins/api_error_handler_mixin.dart';
import '../models/entry_models.dart';

/// Entry 관련 API 서비스
class EntryService with ApiErrorHandlerMixin {
  final DioClient _dioClient;

  EntryService(this._dioClient);

  /// NFC 티켓 입장 처리
  Future<ApiResult<EntryResultModel>> processNfcEntry(
    EntryRequestModel request,
  ) async {
    return await _dioClient.postResult<EntryResultModel>(
      ApiConstants.entryNFC,
      data: request.toJson(),
      parser: (data) {
        final result = EntryResultModel.fromJson(data);
        AppLogger.success(
          'NFC 입장 처리 완료: ${result.isSuccess ? "성공" : "실패"}', 
          'ENTRY_SERVICE'
        );
        return result;
      },
    );
  }

  /// 수동 티켓 입장 처리
  Future<ApiResult<EntryResultModel>> processManualEntry(
    EntryRequestModel request,
  ) async {
    return await _dioClient.postResult<EntryResultModel>(
      ApiConstants.entryNFC, // 같은 엔드포인트 사용 (엔트리 방식은 데이터로 구분)
      data: request.toJson(),
      parser: (data) {
        final result = EntryResultModel.fromJson(data);
        AppLogger.success(
          '수동 입장 처리 완료: ${result.isSuccess ? "성공" : "실패"}', 
          'ENTRY_SERVICE'
        );
        return result;
      },
    );
  }

  /// 입장 내역 조회
  Future<ApiResult<List<EntryHistoryModel>>> getEntryHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = <String, dynamic>{
      'user_id': userId,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    return await _dioClient.postResult<List<EntryHistoryModel>>(
      '/entry/history/', // 가상 엔드포인트 (실제 API에 따라 변경)
      data: data,
      parser: (responseData) {
        final List<dynamic> listData = responseData;
        final histories = listData
            .map((json) => EntryHistoryModel.fromJson(json))
            .toList();
        AppLogger.success('입장 내역 ${histories.length}개 조회 성공', 'ENTRY_SERVICE');
        return histories;
      },
    );
  }
}