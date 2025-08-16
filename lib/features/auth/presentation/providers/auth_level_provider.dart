import 'package:flutter/material.dart';

import '../../domain/entities/auth_level_entities.dart';
import '../../domain/entities/verification_result.dart';
import '../../domain/use_cases/manage_auth_level_use_case.dart';

/// 인증 레벨 관리 Provider
class AuthLevelProvider extends ChangeNotifier {
  final ManageAuthLevelUseCase _manageAuthLevelUseCase;

  AuthLevelProvider(this._manageAuthLevelUseCase);

  AuthLevel _currentLevel = AuthLevel.none;
  bool _isLoading = false;
  String? _errorMessage;
  List<UserPrivilege> _privileges = [];
  AuthUpgradeOption? _upgradeOption;

  // Getters
  AuthLevel get currentLevel => _currentLevel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserPrivilege> get privileges => _privileges;
  AuthUpgradeOption? get upgradeOption => _upgradeOption;
  String get currentLevelDisplayName => _currentLevel.displayName;
  String get currentLevelDescription => _currentLevel.description;
  bool get canUpgrade => _upgradeOption != null;

  /// 사용자 인증 레벨 로드
  Future<void> loadUserAuthLevel(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _manageAuthLevelUseCase.getUserAuthLevel(userId);
      
      result.fold(
        (failure) => _setError(failure.message),
        (authLevel) {
          _currentLevel = authLevel;
          _updateDependentData();
        },
      );
    } catch (e) {
      _setError('인증 레벨 조회 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  /// 인증 레벨 업데이트
  void updateAuthLevel(AuthLevel newLevel) {
    _currentLevel = newLevel;
    _updateDependentData();
    notifyListeners();
  }

  /// 본인인증 결과 기록
  Future<bool> recordVerification({
    required int userId,
    required AuthLevel targetLevel,
    required bool isSuccess,
    VerificationResult? verificationResult,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _manageAuthLevelUseCase.recordVerification(
        userId: userId,
        targetLevel: targetLevel,
        isSuccess: isSuccess,
        verificationResult: verificationResult,
      );

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (newAuthLevel) {
          _currentLevel = AuthLevel.fromString(newAuthLevel.value);
          _updateDependentData();
          return true;
        },
      );
    } catch (e) {
      _setError('본인인증 기록 중 오류가 발생했습니다');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 특정 권한 사용 가능 여부 확인
  bool canUsePrivilege(AuthLevel requiredLevel) {
    return _manageAuthLevelUseCase.canUsePrivilege(_currentLevel, requiredLevel);
  }

  /// 권한별 이용 가능 여부 확인
  bool canBookTickets() => canUsePrivilege(AuthLevel.general);
  bool canQuickEntry() => canUsePrivilege(AuthLevel.mobileId);
  bool canTransferTickets() => canUsePrivilege(AuthLevel.mobileIdTotally);

  /// 의존 데이터 업데이트
  void _updateDependentData() {
    _privileges = _manageAuthLevelUseCase.getUserPrivileges(_currentLevel);
    _upgradeOption = _manageAuthLevelUseCase.getUpgradeOption(_currentLevel);
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
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
    _currentLevel = AuthLevel.none;
    _privileges = [];
    _upgradeOption = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}