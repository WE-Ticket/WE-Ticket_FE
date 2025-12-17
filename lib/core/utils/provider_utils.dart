import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_logger.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../shared/presentation/providers/api_provider.dart';
import '../../features/transfer/presentation/providers/transfer_provider.dart';

/// Utility class for standardized provider access patterns
/// This ensures consistent usage across all widgets and screens
class ProviderUtils {
  /// Get AuthProvider with error handling
  static AuthProvider getAuthProvider(BuildContext context, {bool listen = false}) {
    try {
      return Provider.of<AuthProvider>(context, listen: listen);
    } catch (e) {
      AppLogger.error('Failed to get AuthProvider', e, null, 'PROVIDER');
      rethrow;
    }
  }

  /// Get ApiProvider with error handling
  static ApiProvider getApiProvider(BuildContext context, {bool listen = false}) {
    try {
      return Provider.of<ApiProvider>(context, listen: listen);
    } catch (e) {
      AppLogger.error('Failed to get ApiProvider', e, null, 'PROVIDER');
      rethrow;
    }
  }

  /// Get TransferProvider with error handling
  static TransferProvider getTransferProvider(BuildContext context, {bool listen = false}) {
    try {
      return Provider.of<TransferProvider>(context, listen: listen);
    } catch (e) {
      AppLogger.error('Failed to get TransferProvider', e, null, 'PROVIDER');
      rethrow;
    }
  }

  /// Check if user is authenticated
  static bool isUserAuthenticated(BuildContext context) {
    try {
      final authProvider = getAuthProvider(context);
      return authProvider.isLoggedIn;
    } catch (e) {
      AppLogger.error('Failed to check authentication status', e, null, 'AUTH');
      return false;
    }
  }

  /// Get current user ID with null safety
  static int? getCurrentUserId(BuildContext context) {
    try {
      final authProvider = getAuthProvider(context);
      return authProvider.currentUserId;
    } catch (e) {
      AppLogger.error('Failed to get current user ID', e, null, 'AUTH');
      return null;
    }
  }

  /// Safe provider access with fallback
  static T? safeProviderAccess<T>(
    BuildContext context,
    T Function() providerGetter, {
    String? providerName,
  }) {
    try {
      return providerGetter();
    } catch (e) {
      AppLogger.error(
        'Failed to access provider${providerName != null ? ' ($providerName)' : ''}',
        e,
        null,
        'PROVIDER',
      );
      return null;
    }
  }

  /// Execute action with authentication check
  static Future<void> executeWithAuth(
    BuildContext context,
    Future<void> Function() action, {
    VoidCallback? onUnauthenticated,
  }) async {
    if (!isUserAuthenticated(context)) {
      AppLogger.warning('Action requires authentication', 'AUTH');
      onUnauthenticated?.call();
      return;
    }

    try {
      await action();
    } catch (e) {
      AppLogger.error('Failed to execute authenticated action', e, null, 'AUTH');
      rethrow;
    }
  }
}

/// Extension methods for easier provider access
extension ProviderExtensions on BuildContext {
  /// Get AuthProvider without listening to changes
  AuthProvider get authProvider => ProviderUtils.getAuthProvider(this, listen: false);
  
  /// Get AuthProvider and listen to changes
  AuthProvider get watchAuthProvider => ProviderUtils.getAuthProvider(this, listen: true);
  
  /// Get ApiProvider without listening to changes
  ApiProvider get apiProvider => ProviderUtils.getApiProvider(this, listen: false);
  
  /// Get ApiProvider and listen to changes
  ApiProvider get watchApiProvider => ProviderUtils.getApiProvider(this, listen: true);
  
  /// Get TransferProvider without listening to changes
  TransferProvider get transferProvider => ProviderUtils.getTransferProvider(this, listen: false);
  
  /// Get TransferProvider and listen to changes
  TransferProvider get watchTransferProvider => ProviderUtils.getTransferProvider(this, listen: true);
  
  /// Check if user is authenticated
  bool get isAuthenticated => ProviderUtils.isUserAuthenticated(this);
  
  /// Get current user ID
  int? get currentUserId => ProviderUtils.getCurrentUserId(this);
}