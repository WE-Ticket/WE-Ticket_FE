/// 서버에서 오는 다양한 형태의 에러 메시지를 파싱하는 유틸리티
class ErrorMessageParser {
  /// 서버 에러 응답에서 사용자에게 표시할 메시지를 추출
  static String parseErrorMessage(dynamic errorData, [String? fallbackMessage]) {
    if (errorData == null) {
      return fallbackMessage ?? '알 수 없는 오류가 발생했습니다.';
    }

    try {
      // JSON 문자열인 경우 파싱
      Map<String, dynamic> data;
      if (errorData is String) {
        // 이미 문자열로 된 에러 메시지인 경우
        if (!errorData.startsWith('{')) {
          return errorData;
        }
        data = Map<String, dynamic>.from(
          Map.castFrom(errorData as Map),
        );
      } else if (errorData is Map<String, dynamic>) {
        data = errorData;
      } else if (errorData is Map) {
        data = Map<String, dynamic>.from(errorData);
      } else {
        return fallbackMessage ?? '알 수 없는 오류가 발생했습니다.';
      }

      // 다양한 에러 메시지 형태 처리
      
      // 1. Django REST Framework 형태의 non_field_errors
      if (data.containsKey('non_field_errors') && data['non_field_errors'] is List) {
        final errors = data['non_field_errors'] as List;
        if (errors.isNotEmpty) {
          return errors.first.toString();
        }
      }

      // 2. 필드별 에러 처리 (예: {"email": ["이메일 형식이 올바르지 않습니다."]})
      final fieldErrors = <String>[];
      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        
        // 일반적인 에러 메시지 키들은 건너뛰기
        if (_isGeneralErrorKey(key)) continue;
        
        if (value is List && value.isNotEmpty) {
          fieldErrors.add(value.first.toString());
        } else if (value is String && value.isNotEmpty) {
          fieldErrors.add(value);
        }
      }
      
      if (fieldErrors.isNotEmpty) {
        return fieldErrors.first;
      }

      // 3. 일반적인 에러 메시지 키들 처리
      const errorKeys = [
        'error',
        'message', 
        'detail',
        'error_message',
        'msg',
        'description',
        'reason'
      ];
      
      for (final key in errorKeys) {
        if (data.containsKey(key)) {
          final value = data[key];
          if (value is String && value.isNotEmpty) {
            return value;
          } else if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
        }
      }

      // 4. 첫 번째로 발견되는 문자열 값 반환
      for (final value in data.values) {
        if (value is String && value.isNotEmpty) {
          return value;
        } else if (value is List && value.isNotEmpty) {
          final firstItem = value.first;
          if (firstItem is String && firstItem.isNotEmpty) {
            return firstItem;
          }
        }
      }

      return fallbackMessage ?? '알 수 없는 오류가 발생했습니다.';
    } catch (e) {
      // 파싱 실패 시 원본 데이터가 문자열이면 그대로 반환
      if (errorData is String) {
        return errorData;
      }
      return fallbackMessage ?? '알 수 없는 오류가 발생했습니다.';
    }
  }

  /// 일반적인 에러 메시지 키인지 확인
  static bool _isGeneralErrorKey(String key) {
    const generalKeys = [
      'error',
      'message', 
      'detail',
      'error_message',
      'msg',
      'description',
      'reason',
      'non_field_errors',
      'status_code',
      'code',
      'timestamp',
      'path',
      'success'
    ];
    return generalKeys.contains(key.toLowerCase());
  }

  /// 여러 에러 메시지를 합치기 (필드별 에러를 모두 표시하고 싶을 때)
  static String parseMultipleErrors(dynamic errorData, [String? fallbackMessage]) {
    if (errorData == null) {
      return fallbackMessage ?? '알 수 없는 오류가 발생했습니다.';
    }

    try {
      Map<String, dynamic> data;
      if (errorData is String) {
        if (!errorData.startsWith('{')) {
          return errorData;
        }
        data = Map<String, dynamic>.from(
          Map.castFrom(errorData as Map),
        );
      } else if (errorData is Map<String, dynamic>) {
        data = errorData;
      } else if (errorData is Map) {
        data = Map<String, dynamic>.from(errorData);
      } else {
        return fallbackMessage ?? '알 수 없는 오류가 발생했습니다.';
      }

      final errorMessages = <String>[];

      // non_field_errors 처리
      if (data.containsKey('non_field_errors') && data['non_field_errors'] is List) {
        final errors = data['non_field_errors'] as List;
        for (final error in errors) {
          if (error.toString().isNotEmpty) {
            errorMessages.add(error.toString());
          }
        }
      }

      // 필드별 에러들 처리
      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (_isGeneralErrorKey(key)) continue;
        
        if (value is List) {
          for (final item in value) {
            if (item.toString().isNotEmpty) {
              errorMessages.add(item.toString());
            }
          }
        } else if (value is String && value.isNotEmpty) {
          errorMessages.add(value);
        }
      }

      if (errorMessages.isNotEmpty) {
        return errorMessages.join('\n');
      }

      // 일반 에러 메시지 키들 확인
      return parseErrorMessage(errorData, fallbackMessage);
    } catch (e) {
      if (errorData is String) {
        return errorData;
      }
      return fallbackMessage ?? '알 수 없는 오류가 발생했습니다.';
    }
  }

  /// 에러 코드와 메시지를 함께 파싱
  static Map<String, dynamic> parseErrorWithCode(dynamic errorData) {
    final message = parseErrorMessage(errorData);
    int? statusCode;
    String? errorCode;

    if (errorData is Map<String, dynamic>) {
      statusCode = errorData['status_code'] ?? errorData['code'];
      errorCode = errorData['error_code'] ?? errorData['error_type'];
    }

    return {
      'message': message,
      'status_code': statusCode,
      'error_code': errorCode,
    };
  }
}