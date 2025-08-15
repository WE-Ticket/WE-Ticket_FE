class ApiConstants {
  // Base URL
  static const String baseUrl = 'http://43.201.185.8:8000/api';

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
      '/tickets/performance/{performance_id}/session/{performance_session_id}/zone/{seat_zone}/layout/';

  static const String createTicket = '/tickets/create/';
  static const String entryNFC = '/tickets/gate-entry-start/';

  // Transfer
  static const String transferTicketList = '/transfers/ticket-list/';
  static const String transferTicketDetail =
      '/transfers/ticket-detail/{transfer_ticket_id}/';
  static const String uniqueCodeLookup = '/transfers/unique-code-lookup/';
  static const String uniqueCodeRegeneration =
      '/transfers/unique-code-regeneration/';
  static const String myRegisteredTickets =
      '/transfers/my-ticket-list/registered/';
  static const String myTransferableTickets =
      '/transfers/my-ticket-list/transferable/';
  static const String transferTicketRegitster =
      "/transfers/transfer-ticket-register/";
  static const String transferTicketTogglePublic =
      '/transfers/transfer-ticket-toggle-public/';
  static const String transferTicketCancel =
      '/transfers/transfer-ticket-cancel/';
  static const String lookupPrivateTicket = '/transfers/private-ticket-lookup/';
  static const String processTransfer = '/transfers/transfer-process/';

  // My Page
  static const String myTickets = '/tickets/my-page/owned-ticket-list/';
  static const String myPurchases = '/tickets/my-page/touched-ticket-list/';
  static const String myTicketDetail = '/tickets/my-ticket-detail/';
  static const String paymentHistory = '/tickets/my-page/payment-history/';

  // User
  static const String login = '/users/login/';
  static const String signup = '/users/signup/';
  static const String loadUserAuthLevel = '/users/identity-verification-level/';
  static const String updateUserAuthLevel =
      '/users/identity-verification-record/';
  static const String userMyPage = '/users/my-page/';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
