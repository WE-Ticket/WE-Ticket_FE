import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/did_entities.dart';
import '../../domain/use_cases/manage_did_use_case.dart';

/// DID 관리 Provider
class DidProvider extends ChangeNotifier {
  final ManageDidUseCase _manageDidUseCase;
  StreamSubscription<DidCreationProgress>? _progressSubscription;

  DidProvider(this._manageDidUseCase) {
    _listenToProgress();
  }

  DidCreationResult? _didResult;
  DidCreationProgress _progress = DidCreationProgress.idle();
  String? _errorMessage;

  // Getters
  DidCreationResult? get didResult => _didResult;
  DidCreationProgress get progress => _progress;
  String? get errorMessage => _errorMessage;
  bool get isCreating => _progress.isInProgress;
  bool get isCompleted => _progress.isCompleted;
  bool get hasFailed => _progress.isFailed;
  String? get userDid => _didResult?.did;

  /// DID 생성 및 등록 실행
  Future<bool> createAndRegisterDid({required int userId}) async {
    _clearError();

    try {
      final result = await _manageDidUseCase.createAndRegisterDid(
        userId: userId,
      );

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (didResult) {
          _didResult = didResult;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      AppLogger.error('DID 생성 중 예상치 못한 오류', e, null, 'DID');
      AppLogger.info('Error details: $e', 'DID');
      _setError('DID 생성 중 예상치 못한 오류: $e');
      return false;
    }
  }

  /// DID 삭제
  Future<bool> deleteDid() async {
    _clearError();

    try {
      final result = await _manageDidUseCase.deleteDid();

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (_) {
          _didResult = null;
          _progress = DidCreationProgress.idle();
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _setError('DID 삭제 중 오류가 발생했습니다');
      return false;
    }
  }

  /// DID 생성 진행상태 수신
  void _listenToProgress() {
    _progressSubscription = _manageDidUseCase
        .getCreationProgressStream()
        .listen((progress) {
          _progress = progress;

          if (progress.isFailed && progress.error != null) {
            _setError(progress.error!);
          }

          notifyListeners();
        });
  }

  /// 에러 메시지 설정
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 에러 메시지 초기화
  void _clearError() {
    _errorMessage = null;
  }

  /// 에러 초기화 (외부 호출용)
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// 상태 초기화
  void reset() {
    _didResult = null;
    _progress = DidCreationProgress.idle();
    _errorMessage = null;
    notifyListeners();
  }

  /// DID 정보 포맷팅
  Map<String, String> getDidInfo() {
    if (_didResult == null) return {};

    return {
      'DID': _didResult!.did,
      'Key ID': _didResult!.keyId,
      'Public Key': _didResult!.displayPublicKey,
      'Storage': _didResult!.keyAttestation.storage,
      'Algorithm': _didResult!.keyAttestation.algorithm,
      'Created At': _didResult!.keyAttestation.createdAt,
    };
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }
}
