import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';

/// Network module for dependency injection
/// Handles all network-related dependencies
class NetworkModule {
  static void init(GetIt sl) {
    AppLogger.debug('Initializing network module...', 'DI');
    
    // DioClient with configuration
    sl.registerLazySingleton<DioClient>(() {
      AppLogger.debug('Creating DioClient instance', 'DI');
      return DioClient();
    });
    
    AppLogger.debug('Network module initialized', 'DI');
  }
}