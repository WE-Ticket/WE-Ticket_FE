import 'package:flutter/foundation.dart';

/// Centralized logging utility to replace print statements
class AppLogger {
  static const String _tag = 'WE-Ticket';
  
  /// Log debug information (only in debug mode)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final logTag = tag ?? _tag;
      debugPrint('🐛 [$logTag] $message');
    }
  }

  /// Log general information
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final logTag = tag ?? _tag;
      debugPrint('ℹ️ [$logTag] $message');
    }
  }

  /// Log warnings
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final logTag = tag ?? _tag;
      debugPrint('⚠️ [$logTag] $message');
    }
  }

  /// Log errors
  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    final logTag = tag ?? _tag;
    debugPrint('❌ [$logTag] $message');
    if (error != null) {
      debugPrint('Error details: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Log successful operations
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      final logTag = tag ?? _tag;
      debugPrint('✅ [$logTag] $message');
    }
  }

  /// Log API requests
  static void apiRequest(String method, String endpoint, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      debugPrint('🔐 [API] $method $endpoint');
      if (data != null) {
        debugPrint('Request data: $data');
      }
    }
  }

  /// Log API responses
  static void apiResponse(String endpoint, int statusCode, [dynamic data]) {
    if (kDebugMode) {
      final status = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      debugPrint('$status [API] $endpoint - $statusCode');
      if (data != null && kDebugMode) {
        debugPrint('Response data: $data');
      }
    }
  }

  /// Log authentication events
  static void auth(String message) {
    if (kDebugMode) {
      debugPrint('🔑 [AUTH] $message');
    }
  }

  /// Log navigation events
  static void navigation(String message) {
    if (kDebugMode) {
      debugPrint('🧭 [NAV] $message');
    }
  }
}