class ApiConstants {
  // Base URL
  static const String baseUrl = 'http://13.236.171.188:8000/api';

  // Endpoints
  // Performance
  static const String availablePerformances = '/performances/available/';
  static const String hotPerformances = '/performances/hot/';
  static const String performancesList = '/performances/list/';
  static const String performanceDetail = '/performances/{performance_id}/';

  // Ticket
  static const String performanceSchedule =
      '/tickets/performances/{performance_id}/schedule/';
  static const String sessionSeats =
      '/tickets/performance/{performance_id}/session/{performance_session_id}/seats/';
  static const String seatLayout =
      '/tickets/performance/{performance_id}/session/{performance_session_id}/zone/{seat_zone}';
  static const String createTicket = '/tickets/create';

  // User
  static const String login = '/users/login/';
  static const String signup = '/users/signup/';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
