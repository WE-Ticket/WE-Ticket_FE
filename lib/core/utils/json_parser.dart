/// JSON 파싱 유틸리티
/// API 응답에서 null이나 타입 불일치를 안전하게 처리하기 위한 헬퍼 메서드들
class JsonParserUtils {
  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static double parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static String parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  static bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on';
    }
    if (value is int) return value == 1;
    return defaultValue;
  }

  static List<String> parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((item) => parseString(item))
          .where((str) => str.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((str) => str.isNotEmpty)
          .toList();
    }
    return [];
  }

  static List<int> parseIntList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => parseInt(item)).toList();
    }
    return [];
  }

  static Map<String, dynamic> parseMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  /// DateTime 파싱 (통합된 버전 - dynamic과 String 모두 지원)
  static DateTime parseDateTime(dynamic value, {DateTime? defaultValue}) {
    defaultValue ??= DateTime.now();

    if (value == null) return defaultValue;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // ISO 8601 형식 파싱 시도
        return DateTime.parse(value);
      } catch (e) {
        try {
          // "2025-07-01 10:30:00" 형식
          if (value.contains(' ')) {
            return DateTime.parse(value.replaceAll(' ', 'T'));
          }

          // "2025.07.01" 형식
          if (value.contains('.')) {
            final parts = value.split('.');
            if (parts.length >= 3) {
              final year = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final day = int.parse(parts[2]);
              return DateTime(year, month, day);
            }
          }

          // "2025-07-13" 형태
          if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
            return DateTime.parse('${value}T00:00:00Z');
          }
        } catch (e2) {
          print('❌ DateTime 파싱 실패: $value, 오류: $e2');
        }
      }
    }
    return defaultValue;
  }

  // (날짜만, 시간 제외)
  static DateTime parseDateOnly(dynamic value, {DateTime? defaultValue}) {
    final dateTime = parseDateTime(value, defaultValue: defaultValue);
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Nullable DateTime 파싱
  static DateTime? parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isEmpty) return null;
    try {
      return parseDateTime(value);
    } catch (e) {
      print('❌ Nullable DateTime 파싱 실패: $value, 오류: $e');
      return null;
    }
  }

  /// null 체크
  static bool isNullOrEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  static T safeListAccess<T>(List<T>? list, int index, T defaultValue) {
    if (list == null || index < 0 || index >= list.length) {
      return defaultValue;
    }
    return list[index];
  }

  static T safeMapAccess<T>(
    Map<String, dynamic>? map,
    String key,
    T defaultValue,
  ) {
    if (map == null || !map.containsKey(key)) {
      return defaultValue;
    }
    final value = map[key];
    if (value is T) return value;
    return defaultValue;
  }

  // ==================== ID 파싱 관련 추가 메서드들 ====================

  /// ID 값을 안전하게 int로 파싱 (복합 문자열 지원)
  ///
  /// 지원하는 형태:
  /// - int: 1, 2, 3...
  /// - String (숫자): "1", "2", "3"...
  /// - String (접두사 포함): "upcoming_1", "hot_2", "performance_123"...
  ///
  /// [extractNumber] true면 문자열에서 숫자 부분만 추출
  static int parseId(
    dynamic value, {
    int defaultValue = 0,
    bool extractNumber = true,
  }) {
    if (value == null) return defaultValue;

    // 이미 int인 경우
    if (value is int) {
      return value > 0 ? value : defaultValue;
    }

    // String인 경우
    if (value is String) {
      // 1. 전체가 숫자인지 확인
      final directParse = int.tryParse(value);
      if (directParse != null) {
        return directParse > 0 ? directParse : defaultValue;
      }

      // 2. extractNumber가 true면 문자열에서 숫자 부분 추출
      if (extractNumber) {
        final numberMatch = RegExp(r'\d+').firstMatch(value);
        if (numberMatch != null) {
          final extractedNumber = int.tryParse(numberMatch.group(0)!);
          if (extractedNumber != null && extractedNumber > 0) {
            return extractedNumber;
          }
        }
      }
    }

    return defaultValue;
  }

  /// 공연 데이터에서 ID 추출 (여러 필드 시도)
  static int? extractPerformanceId(Map<String, dynamic>? data) {
    if (data == null) return null;

    // 우선순위대로 ID 필드 확인
    final candidates = [
      'performance_id',
      'performanceId',
      'id',
      'showId',
      'show_id',
    ];

    for (final key in candidates) {
      if (data.containsKey(key)) {
        final id = parseId(data[key], extractNumber: true);
        if (id > 0) {
          return id;
        }
      }
    }

    return null;
  }

  /// 세션 데이터에서 ID 추출
  static int? extractSessionId(Map<String, dynamic>? data) {
    if (data == null) return null;

    final candidates = [
      'performance_session_id',
      'performanceSessionId',
      'session_id',
      'sessionId',
      'id',
    ];

    for (final key in candidates) {
      if (data.containsKey(key)) {
        final id = parseId(data[key], extractNumber: true);
        if (id > 0) {
          return id;
        }
      }
    }

    return null;
  }

  /// 사용자 데이터에서 ID 추출
  static int? extractUserId(Map<String, dynamic>? data) {
    if (data == null) return null;

    final candidates = ['user_id', 'userId', 'id'];

    for (final key in candidates) {
      if (data.containsKey(key)) {
        final id = parseId(data[key], extractNumber: true);
        if (id > 0) {
          return id;
        }
      }
    }

    return null;
  }

  /// ID 유효성 검사
  static bool isValidId(dynamic value) {
    final parsed = parseId(value, extractNumber: true);
    return parsed > 0;
  }

  /// API URL에서 ID 추출 (예: "/api/performances/123/schedule" -> 123)
  static int? extractIdFromUrl(String url) {
    final match = RegExp(r'/(\d+)/').firstMatch(url);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// 디버깅을 위한 ID 파싱 과정 출력
  static int? parseIdWithDebug(
    dynamic value, {
    String? context,
    bool extractNumber = true,
  }) {
    final contextStr = context != null ? '[$context]' : '';
    print('🔍$contextStr ID 파싱 시작: $value (${value.runtimeType})');

    final result = parseId(value, extractNumber: extractNumber);

    if (result > 0) {
      print('✅$contextStr ID 파싱 성공: $value -> $result');
    } else {
      print('❌$contextStr ID 파싱 실패: $value -> 기본값 사용');
    }

    return result > 0 ? result : null;
  }

  /// 공연 ID 추출 (디버깅 포함)
  static int? extractPerformanceIdWithDebug(Map<String, dynamic>? data) {
    if (data == null) {
      print('❌ 공연 ID 추출 실패: 데이터가 null입니다');
      return null;
    }

    print('🔍 공연 ID 추출 시작');
    print('📋 사용 가능한 필드들: ${data.keys.toList()}');

    final candidates = [
      'performance_id',
      'performanceId',
      'id',
      'showId',
      'show_id',
    ];

    for (final key in candidates) {
      if (data.containsKey(key)) {
        final rawValue = data[key];
        final id = parseId(rawValue, extractNumber: true);
        print('🔍 필드 "$key": $rawValue -> $id');

        if (id > 0) {
          print('✅ 공연 ID 추출 성공: $key = $rawValue -> $id');
          return id;
        }
      }
    }

    print('❌ 공연 ID 추출 실패: 유효한 ID 필드를 찾을 수 없음');
    return null;
  }

  /// Nullable Int 파싱
  static int? parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    if (value is double) return value.toInt();
    return null;
  }

  /// Nullable String 파싱
  static String? parseStringNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }
}
