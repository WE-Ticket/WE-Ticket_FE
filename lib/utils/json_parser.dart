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

  static DateTime parseDateTime(dynamic value, {DateTime? defaultValue}) {
    defaultValue ??= DateTime.now();

    if (value == null) return defaultValue;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        try {
          // "2025-07-13" 형태
          if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
            return DateTime.parse('${value}T00:00:00Z');
          }
        } catch (e) {
          // 파싱 실패시 기본값 반환
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
}
