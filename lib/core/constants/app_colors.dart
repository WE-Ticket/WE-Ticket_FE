import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===== Primary Colors (남색 계열) =====
  static const Color primary = Color(0xFF1E3A8A); // 진한 남색 (메인)
  static const Color primaryLight = Color(0xFF3B82F6); // 밝은 남색
  static const Color primaryDark = Color(0xFF1E40AF); // 더 진한 남색
  static const Color primaryAccent = Color(0xFF1D4ED8); // 중간 남색

  // ===== Secondary Colors =====
  static const Color secondary = Color(0xFF64748B); // 슬레이트 그레이
  static const Color secondaryLight = Color(0xFF94A3B8); // 밝은 슬레이트
  static const Color secondaryDark = Color(0xFF475569); // 진한 슬레이트

  // ===== Accent Colors =====
  static const Color success = Color(0xFF059669); // 에메랄드 그린 (성공)
  static const Color successLight = Color(0xFF10B981); // 밝은 그린
  static const Color successDark = Color(0xFF047857); // 진한 그린

  static const Color error = Color(0xFFDC2626); // 따뜻한 레드 (에러)
  static const Color errorLight = Color(0xFFEF4444); // 밝은 레드
  static const Color errorDark = Color(0xFFB91C1C); // 진한 레드

  static const Color warning = Color(0xFFF59E0B); // 앰버 (경고)
  static const Color warningLight = Color(0xFFFBBF24); // 밝은 앰버
  static const Color warningDark = Color(0xFFD97706); // 진한 앰버

  static const Color info = Color(0xFF0EA5E9); // 스카이 블루 (정보)
  static const Color infoLight = Color(0xFF38BDF8); // 밝은 블루
  static const Color infoDark = Color(0xFF0284C7); // 진한 블루

  // ===== Neutral Colors (그레이스케일) =====
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ===== Background Colors =====
  static const Color background = Color(0xFFF9FAFB); // gray50
  static const Color surface = Color(0xFFFFFFFF); // white
  static const Color surfaceVariant = Color(0xFFF3F4F6); // gray100

  // ===== Border Colors =====
  static const Color border = Color(0xFFE5E7EB); // gray200
  static const Color borderLight = Color(0xFFF3F4F6); // gray100
  static const Color borderDark = Color(0xFFD1D5DB); // gray300

  // ===== Text Colors =====
  static const Color textPrimary = Color(0xFF111827); // gray900
  static const Color textSecondary = Color(0xFF6B7280); // gray500
  static const Color textTertiary = Color(0xFF9CA3AF); // gray400
  static const Color textOnPrimary = Color(0xFFFFFFFF); // white
  static const Color textOnSecondary = Color(0xFFFFFFFF); // white

  // ===== Gradient Colors =====
  static const List<Color> primaryGradient = [
    Color(0xFF1E3A8A), // primary
    Color(0xFF3B82F6), // primaryLight
  ];

  static const List<Color> successGradient = [
    Color(0xFF047857), // successDark
    Color(0xFF10B981), // successLight
  ];

  static const List<Color> errorGradient = [
    Color(0xFFB91C1C), // errorDark
    Color(0xFFEF4444), // errorLight
  ];

  static const List<Color> warningGradient = [
    Color(0xFFD97706), // warningDark
    Color(0xFFFBBF24), // warningLight
  ];

  // ===== Shadow Colors =====
  static Color shadowLight = const Color(0xFF000000).withOpacity(0.05);
  static Color shadowMedium = const Color(0xFF000000).withOpacity(0.1);
  static Color shadowDark = const Color(0xFF000000).withOpacity(0.15);
  static Color shadowHeavy = const Color(0xFF000000).withOpacity(0.25);

  // ===== Utility Methods =====

  /// 투명도가 적용된 컬러 반환
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Primary 계열 색상들을 Map으로 반환
  static Map<int, Color> get primarySwatch => {
    50: const Color(0xFFF0F4FF),
    100: const Color(0xFFE0EAFF),
    200: const Color(0xFFC7D8FF),
    300: const Color(0xFFA3BFFF),
    400: const Color(0xFF7A9EFF),
    500: primaryLight,
    600: primary,
    700: primaryDark,
    800: const Color(0xFF1E40AF),
    900: const Color(0xFF1E3A8A),
  };

  /// 테마별 컬러 반환
  static ThemeData getThemeData({bool isDark = false}) {
    if (isDark) {
      // 다크 테마 (추후 구현)
      return ThemeData.dark().copyWith(
        primaryColor: primary,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: gray800,
          background: gray900,
          error: error,
        ),
      );
    } else {
      // 라이트 테마
      return ThemeData.light().copyWith(
        primaryColor: primary,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: surface,
          background: background,
          error: error,
        ),
      );
    }
  }
}
