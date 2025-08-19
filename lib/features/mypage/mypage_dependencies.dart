import 'package:provider/provider.dart';
import '../../injection/injection_container.dart';
import '../../core/network/dio_client.dart';
import 'data/services/mypage_service.dart';
import 'data/mappers/mypage_mapper.dart';
import 'data/repositories/mypage_repository_impl.dart';
import 'domain/repositories/mypage_repository.dart';
import 'domain/use_cases/get_owned_tickets_use_case.dart';
import 'domain/use_cases/get_ticket_detail_use_case.dart';
import 'domain/use_cases/get_payment_history_use_case.dart';
import 'presentation/providers/mypage_provider.dart';
import '../../shared/presentation/providers/api_provider.dart';

class MyPageDependencies {
  /// Get MyPage provider configurations for main app
  static List<ChangeNotifierProxyProvider<ApiProvider, MyPageProvider>>
      getProxyProviders() {
    return [
      ChangeNotifierProxyProvider<ApiProvider, MyPageProvider>(
        create: (context) {
          final apiProvider = Provider.of<ApiProvider>(context, listen: false);
          return _createMyPageProvider(apiProvider.dioClient);
        },
        update: (context, apiProvider, previousMyPageProvider) {
          return previousMyPageProvider ?? 
                 _createMyPageProvider(apiProvider.dioClient);
        },
      ),
    ];
  }

  /// Create MyPageProvider with all dependencies
  static MyPageProvider _createMyPageProvider(DioClient dioClient) {
    // Create service
    final myPageService = MyPageService(dioClient);
    
    // Create mapper
    final mapper = MyPageMapper();
    
    // Create repository
    final repository = MyPageRepositoryImpl(
      service: myPageService,
      mapper: mapper,
    );
    
    // Create use cases
    final getOwnedTicketsUseCase = GetOwnedTicketsUseCase(repository);
    final getTicketDetailUseCase = GetTicketDetailUseCase(repository);
    final getPaymentHistoryUseCase = GetPaymentHistoryUseCase(repository);
    
    // Create provider
    return MyPageProvider(
      getOwnedTicketsUseCase: getOwnedTicketsUseCase,
      getTicketDetailUseCase: getTicketDetailUseCase,
      getPaymentHistoryUseCase: getPaymentHistoryUseCase,
      myPageService: myPageService,
    );
  }

  /// Register dependencies with GetIt (if using service locator)
  static void registerDependencies() {
    // MyPage Service
    sl.registerLazySingleton<MyPageService>(
      () => MyPageService(sl<DioClient>()),
    );
    
    // Mappers
    sl.registerLazySingleton<MyPageMapper>(() => MyPageMapper());
    
    // Repositories
    sl.registerLazySingleton<MyPageRepository>(
      () => MyPageRepositoryImpl(
        service: sl<MyPageService>(),
        mapper: sl<MyPageMapper>(),
      ),
    );
    
    // Use Cases
    sl.registerLazySingleton<GetOwnedTicketsUseCase>(
      () => GetOwnedTicketsUseCase(sl<MyPageRepository>()),
    );
    
    sl.registerLazySingleton<GetTicketDetailUseCase>(
      () => GetTicketDetailUseCase(sl<MyPageRepository>()),
    );
    
    sl.registerLazySingleton<GetPaymentHistoryUseCase>(
      () => GetPaymentHistoryUseCase(sl<MyPageRepository>()),
    );
    
    // Providers
    sl.registerFactory<MyPageProvider>(
      () => MyPageProvider(
        getOwnedTicketsUseCase: sl<GetOwnedTicketsUseCase>(),
        getTicketDetailUseCase: sl<GetTicketDetailUseCase>(),
        getPaymentHistoryUseCase: sl<GetPaymentHistoryUseCase>(),
        myPageService: sl<MyPageService>(),
      ),
    );
  }
}