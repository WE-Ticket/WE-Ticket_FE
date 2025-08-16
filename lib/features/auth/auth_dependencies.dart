/// 클린 아키텍처 의존성 주입 설정
library;

import 'package:provider/provider.dart';

import '../../shared/presentation/providers/api_provider.dart';
import 'auth_exports.dart';
import 'data/auth_service.dart';

/// 인증 관련 Provider들을 위한 의존성 주입 설정
class AuthDependencies {
  /// ApiProvider에 의존하는 새로운 Provider들을 반환
  static List<ChangeNotifierProxyProvider> getProxyProviders() {
    return [
      // AuthLevelProvider
      ChangeNotifierProxyProvider<ApiProvider, AuthLevelProvider>(
        create: (context) {
          final apiProvider = Provider.of<ApiProvider>(context, listen: false);
          final authRepository = AuthRepositoryImpl(AuthService(apiProvider.dioClient));
          final manageAuthLevelUseCase = ManageAuthLevelUseCase(authRepository);
          return AuthLevelProvider(manageAuthLevelUseCase);
        },
        update: (context, apiProvider, previousProvider) {
          if (previousProvider != null) return previousProvider;
          
          final authRepository = AuthRepositoryImpl(AuthService(apiProvider.dioClient));
          final manageAuthLevelUseCase = ManageAuthLevelUseCase(authRepository);
          return AuthLevelProvider(manageAuthLevelUseCase);
        },
      ),
      
      // DidProvider
      ChangeNotifierProxyProvider<ApiProvider, DidProvider>(
        create: (context) {
          final apiProvider = Provider.of<ApiProvider>(context, listen: false);
          final didRepository = DidRepositoryImpl(apiProvider.dioClient);
          final manageDidUseCase = ManageDidUseCase(didRepository);
          return DidProvider(manageDidUseCase);
        },
        update: (context, apiProvider, previousProvider) {
          if (previousProvider != null) return previousProvider;
          
          final didRepository = DidRepositoryImpl(apiProvider.dioClient);
          final manageDidUseCase = ManageDidUseCase(didRepository);
          return DidProvider(manageDidUseCase);
        },
      ),
    ];
  }
}