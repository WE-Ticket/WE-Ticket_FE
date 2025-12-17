import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/network/dio_client.dart';
import '../core/utils/app_logger.dart';
import '../shared/data/services/api_service.dart';
import '../shared/presentation/providers/api_provider.dart';

// Performance feature imports
import '../features/contents/data/performance_service.dart';
import '../features/contents/data/mappers/performance_mapper.dart';
import '../features/contents/data/repositories/performance_repository_impl.dart';
import '../features/contents/domain/repositories/performance_repository.dart';
import '../features/contents/domain/use_cases/get_hot_performances_use_case.dart';
import '../features/contents/domain/use_cases/get_available_performances_use_case.dart';
import '../features/contents/domain/use_cases/get_all_performances_use_case.dart';
import '../features/contents/domain/use_cases/get_performance_detail_use_case.dart';
import '../features/contents/domain/use_cases/get_performances_by_genre_use_case.dart';
import '../features/contents/domain/use_cases/search_performances_use_case.dart';
import '../features/contents/presentation/providers/contents_provider.dart';

// Transfer feature imports
import '../features/transfer/data/transfer_service.dart';
import '../features/transfer/data/mappers/transfer_mapper.dart';
import '../features/transfer/data/repositories/transfer_repository_impl.dart';
import '../features/transfer/domain/repositories/transfer_repository.dart';
import '../features/transfer/domain/use_cases/get_transfer_tickets_use_case.dart';
import '../features/transfer/domain/use_cases/process_transfer_use_case.dart';
import '../features/transfer/domain/use_cases/register_ticket_for_transfer_use_case.dart';
import '../features/transfer/domain/use_cases/get_my_transfer_tickets_use_case.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
/// Call this method in main() before runApp()
Future<void> initializeDependencies() async {
  AppLogger.info('🔧 Initializing dependencies...', 'DI');
  
  // Initialize external dependencies first
  await _initExternalDependencies();
  
  // Initialize core dependencies
  _initCore();
  
  // Initialize shared dependencies
  _initShared();
  
  // Initialize feature dependencies
  _initAuth();
  _initPerformance();
  _initTransfer();
  // TODO: Complete remaining features
  // _initTicketing();
  // _initUserProfile();
  
  AppLogger.success('✅ Dependencies initialized successfully', 'DI');
}

/// Initialize external dependencies (SharedPreferences, etc.)
Future<void> _initExternalDependencies() async {
  AppLogger.debug('Initializing external dependencies...', 'DI');
  
  // SharedPreferences - singleton instance
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  
  AppLogger.debug('External dependencies initialized', 'DI');
}

/// Initialize core dependencies
void _initCore() {
  AppLogger.debug('Initializing core dependencies...', 'DI');
  
  // DioClient - singleton
  sl.registerLazySingleton<DioClient>(() => DioClient());
  
  AppLogger.debug('Core dependencies initialized', 'DI');
}

/// Initialize shared dependencies
void _initShared() {
  AppLogger.debug('Initializing shared dependencies...', 'DI');
  
  // API Service - depends on DioClient
  sl.registerLazySingleton<ApiService>(
    () => ApiService.withCustomClient(sl<DioClient>()),
  );
  
  // API Provider - depends on DioClient and ApiService
  sl.registerFactory<ApiProvider>(() => ApiProvider());
  
  AppLogger.debug('Shared dependencies initialized', 'DI');
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  AppLogger.warning('🔄 Resetting all dependencies...', 'DI');
  await sl.reset();
  AppLogger.info('Dependencies reset complete', 'DI');
}

/// Check if dependencies are properly initialized
bool get isDependenciesInitialized {
  try {
    // Check if core dependencies exist
    sl<SharedPreferences>();
    sl<DioClient>();
    sl<ApiService>();
    return true;
  } catch (e) {
    AppLogger.error('Dependencies not properly initialized', e, null, 'DI');
    return false;
  }
}

/// Get dependency safely with error handling
T? getDependency<T extends Object>() {
  try {
    return sl<T>();
  } catch (e) {
    AppLogger.error('Failed to get dependency ${T.toString()}', e, null, 'DI');
    return null;
  }
}

/// Register a dependency manually (useful for testing)
void registerDependency<T extends Object>(T dependency) {
  if (sl.isRegistered<T>()) {
    sl.unregister<T>();
  }
  sl.registerSingleton<T>(dependency);
  AppLogger.debug('Registered dependency: ${T.toString()}', 'DI');
}

/// Initialize auth feature dependencies
void _initAuth() {
  AppLogger.debug('Initializing auth dependencies...', 'DI');
  // Auth dependencies are already handled in existing auth setup
  AppLogger.debug('Auth dependencies initialized', 'DI');
}

/// Initialize performance feature dependencies
void _initPerformance() {
  AppLogger.debug('Initializing performance dependencies...', 'DI');
  
  // Performance Service
  sl.registerLazySingleton<PerformanceService>(
    () => PerformanceService(sl<DioClient>()),
  );
  
  // Mappers
  sl.registerLazySingleton<PerformanceMapper>(() => PerformanceMapper());
  
  // Repositories
  sl.registerLazySingleton<PerformanceRepository>(
    () => PerformanceRepositoryImpl(
      sl<PerformanceService>(),
      sl<PerformanceMapper>(),
    ),
  );
  
  // Use Cases
  sl.registerLazySingleton<GetHotPerformancesUseCase>(
    () => GetHotPerformancesUseCase(sl<PerformanceRepository>()),
  );
  
  sl.registerLazySingleton<GetAvailablePerformancesUseCase>(
    () => GetAvailablePerformancesUseCase(sl<PerformanceRepository>()),
  );
  
  sl.registerLazySingleton<GetAllPerformancesUseCase>(
    () => GetAllPerformancesUseCase(sl<PerformanceRepository>()),
  );
  
  sl.registerLazySingleton<GetPerformanceDetailUseCase>(
    () => GetPerformanceDetailUseCase(sl<PerformanceRepository>()),
  );
  
  sl.registerLazySingleton<GetPerformancesByGenreUseCase>(
    () => GetPerformancesByGenreUseCase(sl<PerformanceRepository>()),
  );
  
  sl.registerLazySingleton<SearchPerformancesUseCase>(
    () => SearchPerformancesUseCase(sl<PerformanceRepository>()),
  );
  
  // Providers
  sl.registerFactory<ContentsProvider>(
    () => ContentsProvider(
      performanceService: sl<PerformanceService>(),
    ),
  );
  
  AppLogger.debug('Performance dependencies initialized', 'DI');
}

/// Initialize transfer feature dependencies
void _initTransfer() {
  AppLogger.debug('Initializing transfer dependencies...', 'DI');
  
  // Transfer Service
  sl.registerLazySingleton<TransferService>(
    () => TransferService(sl<DioClient>()),
  );
  
  // Mappers
  sl.registerLazySingleton<TransferMapper>(() => TransferMapper());
  
  // Repositories
  sl.registerLazySingleton<TransferRepository>(
    () => TransferRepositoryImpl(
      sl<TransferService>(),
      sl<TransferMapper>(),
    ),
  );
  
  // Use Cases
  sl.registerLazySingleton<GetTransferTicketsUseCase>(
    () => GetTransferTicketsUseCase(sl<TransferRepository>()),
  );
  
  sl.registerLazySingleton<ProcessTransferUseCase>(
    () => ProcessTransferUseCase(sl<TransferRepository>()),
  );
  
  sl.registerLazySingleton<RegisterTicketForTransferUseCase>(
    () => RegisterTicketForTransferUseCase(sl<TransferRepository>()),
  );
  
  sl.registerLazySingleton<GetMyTransferTicketsUseCase>(
    () => GetMyTransferTicketsUseCase(sl<TransferRepository>()),
  );
  
  AppLogger.debug('Transfer dependencies initialized', 'DI');
}