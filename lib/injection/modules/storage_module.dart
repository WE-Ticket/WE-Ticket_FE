import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';

/// Storage module for dependency injection
/// Handles all storage-related dependencies
class StorageModule {
  static Future<void> init(GetIt sl) async {
    AppLogger.debug('Initializing storage module...', 'DI');
    
    // SharedPreferences - needs to be initialized asynchronously
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
    
    AppLogger.debug('Storage module initialized', 'DI');
  }
}