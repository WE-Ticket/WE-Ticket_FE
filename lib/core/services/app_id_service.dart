import 'package:flutter/services.dart';

class AppIdService {
  static const platform = MethodChannel('did_sdk');

  /// 앱 ID 정보 가져오기
  static Future<Map<String, dynamic>?> getAppId() async {
    try {
      print('[AppIdService] 앱 ID 조회 시작');
      
      final response = await platform.invokeMethod('getAppId');
      final result = _safeMapConversion(response);
      
      if (result['success'] == true) {
        print('[AppIdService] 앱 ID 조회 성공');
        print('[AppIdService] 앱 ID: ${result['appId']}');
        print('[AppIdService] 서명 해시: ${result['signatureHash']}');
        print('[AppIdService] 설치 시간: ${result['installTime']}');
        print('[AppIdService] 업데이트 시간: ${result['lastUpdateTime']}');
        print('[AppIdService] 새로 설치된 앱인가?: ${result['isNewInstall']}');
        
        return result;
      } else {
        print('[AppIdService] ❌ 앱 ID 조회 실패: ${result['error']}');
        return null;
      }
    } on PlatformException catch (e) {
      print('[AppIdService] ❌ 플랫폼 오류: ${e.message}');
      return null;
    } catch (e) {
      print('[AppIdService] ❌ 예상치 못한 오류: $e');
      return null;
    }
  }

  /// 안전한 Map 변환 헬퍼 함수
  static Map<String, dynamic> _safeMapConversion(dynamic input) {
    if (input == null) return <String, dynamic>{};
    if (input is Map<String, dynamic>) return input;
    if (input is Map) {
      return Map<String, dynamic>.from(
        input.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return <String, dynamic>{};
  }

  /// 로그인 시 앱 ID 정보 출력 (테스트용)
  static Future<void> printAppIdOnLogin() async {
    print('=== 로그인 시 앱 ID 확인 ===');
    
    final appIdInfo = await getAppId();
    
    if (appIdInfo != null) {
      print('📱 앱 정보:');
      print('   - 앱 ID: ${appIdInfo['appId']}');
      print('   - 서명 해시: ${appIdInfo['signatureHash']}');
      print('   - 설치 시간: ${DateTime.fromMillisecondsSinceEpoch(appIdInfo['installTime'])}');
      print('   - 마지막 업데이트: ${DateTime.fromMillisecondsSinceEpoch(appIdInfo['lastUpdateTime'])}');
      print('   - 새로 설치된 앱: ${appIdInfo['isNewInstall'] ? '예' : '아니오'}');
      
      if (appIdInfo['isNewInstall'] == true) {
        print('🆕 이 앱은 새로 설치되었습니다!');
      } else {
        print('🔄 이 앱은 이전에 설치된 적이 있습니다.');
      }
    } else {
      print('❌ 앱 ID 정보를 가져올 수 없습니다.');
    }
    
    print('=== 앱 ID 확인 완료 ===');
  }
}