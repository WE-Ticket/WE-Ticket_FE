/// Application configuration constants
class AppConfig {
  // App Information
  static const String appName = 'WE-Ticket';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // API Configuration
  static const String baseUrl = 'http://43.201.185.8:8000/api';
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);
  
  // Cache Configuration
  static const Duration defaultCacheExpiry = Duration(minutes: 5);
  static const Duration userDataCacheExpiry = Duration(hours: 1);
  static const Duration performanceCacheExpiry = Duration(minutes: 10);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Security
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  
  // Feature Flags
  static const bool enableLogging = true;
  static const bool enableCrashlytics = false;
  static const bool enableAnalytics = false;
  
  // NFC Configuration
  static const Duration nfcTimeout = Duration(seconds: 30);
  static const String nfcErrorMessage = 'NFC 통신 중 오류가 발생했습니다.';
  
  // Payment Configuration
  static const Duration paymentTimeout = Duration(minutes: 10);
  
  // Localization
  static const String defaultLocale = 'ko';
  static const List<String> supportedLocales = ['ko', 'en'];
}