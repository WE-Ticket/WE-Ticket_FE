import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// 기기에서 생체 인증이 가능한지 확인
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// 등록된 생체 인증 방법이 있는지 확인
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// 사용 가능한 생체 인증 방법 목록 가져오기
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// 생체 인증 실행
  static Future<bool> authenticateWithBiometrics() async {
    try {
      print('[BiometricService] 생체 인증 시작');
      
      final bool canCheck = await canCheckBiometrics();
      print('[BiometricService] canCheckBiometrics: $canCheck');
      if (!canCheck) {
        print('[BiometricService] 기기에서 생체 인증을 확인할 수 없습니다');
        return false;
      }

      final bool isSupported = await isDeviceSupported();
      print('[BiometricService] isDeviceSupported: $isSupported');
      if (!isSupported) {
        print('[BiometricService] 기기에서 생체 인증을 지원하지 않습니다');
        return false;
      }

      final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
      print('[BiometricService] availableBiometrics: $availableBiometrics');
      if (availableBiometrics.isEmpty) {
        print('[BiometricService] 등록된 생체 인증이 없습니다');
        return false;
      }

      print('[BiometricService] 생체 인증 대화상자 표시');
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: '생체 인증을 통해 본인 확인을 진행해주세요',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      print('[BiometricService] 생체 인증 결과: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      print('[BiometricService] 생체 인증 중 오류 발생: $e');
      return false;
    }
  }

  /// 생체 인증 상태 확인 (사용 가능 여부)
  static Future<BiometricAuthStatus> checkBiometricStatus() async {
    try {
      final bool canCheck = await canCheckBiometrics();
      if (!canCheck) return BiometricAuthStatus.notAvailable;

      final bool isSupported = await isDeviceSupported();
      if (!isSupported) return BiometricAuthStatus.notSupported;

      final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) return BiometricAuthStatus.notEnrolled;

      return BiometricAuthStatus.available;
    } catch (e) {
      return BiometricAuthStatus.error;
    }
  }
}

enum BiometricAuthStatus {
  available,    // 사용 가능
  notAvailable, // 기기에서 생체 인증 미지원
  notSupported, // 하드웨어 미지원
  notEnrolled,  // 등록된 생체 인증 없음
  error,        // 오류 발생
}