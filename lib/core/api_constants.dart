class ApiConstants {
  // Base URL
  static const String baseUrl = 'http://13.236.171.188:8000/api';

  // Endpoints
  static const String availablePerformances = '/performances/available/';
  static const String hotPerformances = '/performances/hot/';
  static const String performancesList = '/performances/list/';
  static const String performanceDetail = '/performances/{performance_id}/';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
