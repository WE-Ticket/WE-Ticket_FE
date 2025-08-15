import 'package:flutter/foundation.dart';
import '../../domain/entities/entry_result.dart';
import '../../domain/use_cases/process_nfc_entry_use_case.dart';
import '../../domain/use_cases/process_manual_entry_use_case.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_logger.dart';

/// Entry 기능을 관리하는 Provider
/// NFC 입장, 수동 입장 등의 상태를 관리합니다.
class EntryProvider extends ChangeNotifier {
  final ProcessNfcEntryUseCase _processNfcEntryUseCase;
  final ProcessManualEntryUseCase _processManualEntryUseCase;

  // 상태 관리
  bool _isLoading = false;
  String? _errorMessage;
  EntryResult? _lastEntryResult;
  
  // NFC 관련 상태
  bool _isNfcReading = false;
  String? _nfcData;
  
  // 수동 입장 관련 상태
  String? _manualCode;

  EntryProvider({
    required ProcessNfcEntryUseCase processNfcEntryUseCase,
    required ProcessManualEntryUseCase processManualEntryUseCase,
  })  : _processNfcEntryUseCase = processNfcEntryUseCase,
        _processManualEntryUseCase = processManualEntryUseCase;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  EntryResult? get lastEntryResult => _lastEntryResult;
  bool get isNfcReading => _isNfcReading;
  String? get nfcData => _nfcData;
  String? get manualCode => _manualCode;

  /// NFC 입장 처리
  Future<void> processNfcEntry({
    required String ticketId,
    required String userId,
    required String nfcData,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('NFC 입장 처리 시작 (ticketId: $ticketId)', 'ENTRY');

      final result = await _processNfcEntryUseCase.call(
        ProcessNfcEntryParams(
          ticketId: ticketId,
          userId: userId,
          nfcData: nfcData,
        ),
      );

      result.fold(
        (failure) {
          final errorMsg = _mapFailureToMessage(failure);
          AppLogger.error('NFC 입장 처리 실패: $errorMsg', null, null, 'ENTRY');
          _setError(errorMsg);
        },
        (entryResult) {
          _lastEntryResult = entryResult;
          if (entryResult.isSuccess) {
            AppLogger.success('NFC 입장 성공: ${entryResult.message}', 'ENTRY');
          } else {
            AppLogger.warning('NFC 입장 거부: ${entryResult.message}', 'ENTRY');
            _setError(entryResult.message);
          }
        },
      );
    } catch (e) {
      AppLogger.error('NFC 입장 처리 예외', e, null, 'ENTRY');
      _setError('NFC 입장 처리 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 수동 입장 처리
  Future<void> processManualEntry({
    required String ticketId,
    required String userId,
    required String manualCode,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('수동 입장 처리 시작 (ticketId: $ticketId)', 'ENTRY');

      final result = await _processManualEntryUseCase.call(
        ProcessManualEntryParams(
          ticketId: ticketId,
          userId: userId,
          manualCode: manualCode,
        ),
      );

      result.fold(
        (failure) {
          final errorMsg = _mapFailureToMessage(failure);
          AppLogger.error('수동 입장 처리 실패: $errorMsg', null, null, 'ENTRY');
          _setError(errorMsg);
        },
        (entryResult) {
          _lastEntryResult = entryResult;
          if (entryResult.isSuccess) {
            AppLogger.success('수동 입장 성공: ${entryResult.message}', 'ENTRY');
          } else {
            AppLogger.warning('수동 입장 거부: ${entryResult.message}', 'ENTRY');
            _setError(entryResult.message);
          }
        },
      );
    } catch (e) {
      AppLogger.error('수동 입장 처리 예외', e, null, 'ENTRY');
      _setError('수동 입장 처리 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// NFC 읽기 시작
  void startNfcReading() {
    _isNfcReading = true;
    _clearError();
    AppLogger.info('NFC 읽기 시작', 'ENTRY');
    notifyListeners();
  }

  /// NFC 읽기 중지
  void stopNfcReading() {
    _isNfcReading = false;
    _nfcData = null;
    AppLogger.info('NFC 읽기 중지', 'ENTRY');
    notifyListeners();
  }

  /// NFC 데이터 설정
  void setNfcData(String data) {
    _nfcData = data;
    _isNfcReading = false;
    AppLogger.info('NFC 데이터 설정 완료', 'ENTRY');
    notifyListeners();
  }

  /// 수동 코드 설정
  void setManualCode(String code) {
    _manualCode = code;
    AppLogger.info('수동 코드 설정 완료', 'ENTRY');
    notifyListeners();
  }

  /// 입장 결과 클리어
  void clearEntryResult() {
    _lastEntryResult = null;
    AppLogger.info('입장 결과 클리어', 'ENTRY');
    notifyListeners();
  }

  /// 모든 상태 리셋
  void reset() {
    _lastEntryResult = null;
    _isNfcReading = false;
    _nfcData = null;
    _manualCode = null;
    _clearError();
    AppLogger.info('Entry 상태 리셋', 'ENTRY');
    notifyListeners();
  }

  /// 에러 메시지 클리어
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return '네트워크 연결을 확인해주세요';
    } else {
      return '알 수 없는 오류가 발생했습니다';
    }
  }

  @override
  void dispose() {
    AppLogger.info('EntryProvider dispose', 'ENTRY');
    super.dispose();
  }
}