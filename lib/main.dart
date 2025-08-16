import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:we_ticket/core/utils/app_logger.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/features/auth/auth_dependencies.dart';
import 'package:we_ticket/features/contents/presentation/screens/dashboard_screen.dart';
import 'package:we_ticket/features/contents/presentation/providers/contents_provider.dart';
import 'package:we_ticket/features/contents/data/performance_service.dart';
import 'package:we_ticket/features/transfer/presentation/providers/transfer_provider.dart';
import 'package:we_ticket/injection/injection_container.dart';
import 'package:we_ticket/shared/presentation/providers/api_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  try {
    await initializeDependencies();
    AppLogger.success('🚀 App starting with Clean Architecture setup', 'MAIN');
  } catch (e) {
    AppLogger.error('Failed to initialize dependencies', e, null, 'MAIN');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ 1. ApiProvider를 먼저 생성 (DioClient 포함)
        ChangeNotifierProvider(create: (_) => ApiProvider()),

        // ✅ 2. AuthProvider는 ApiProvider의 DioClient를 사용
        ChangeNotifierProxyProvider<ApiProvider, AuthProvider>(
          create: (context) {
            final apiProvider = Provider.of<ApiProvider>(
              context,
              listen: false,
            );
            return AuthProvider(apiProvider.dioClient);
          },
          update: (context, apiProvider, previousAuthProvider) {
            // 기존 AuthProvider가 있으면 재사용, 없으면 새로 생성
            return previousAuthProvider ?? AuthProvider(apiProvider.dioClient);
          },
        ),

        // ✅ 3. ContentsProvider는 ApiProvider의 DioClient를 사용
        ChangeNotifierProxyProvider<ApiProvider, ContentsProvider>(
          create: (context) {
            final apiProvider = Provider.of<ApiProvider>(context, listen: false);
            return ContentsProvider(
              performanceService: PerformanceService(apiProvider.dioClient),
            );
          },
          update: (context, apiProvider, previousContentsProvider) {
            return previousContentsProvider ??
                ContentsProvider(
                  performanceService: PerformanceService(apiProvider.dioClient),
                );
          },
        ),

        // ✅ 4. TransferProvider는 ApiProvider에 의존
        ChangeNotifierProxyProvider<ApiProvider, TransferProvider>(
          create: (context) => TransferProvider(
            Provider.of<ApiProvider>(context, listen: false).apiService,
          ),
          update: (context, apiProvider, previousTransferProvider) =>
              previousTransferProvider ??
              TransferProvider(apiProvider.apiService),
        ),

        // ✅ 5. 새로운 Clean Architecture Providers
        ...AuthDependencies.getProxyProviders(),
      ],
      child: MaterialApp(
        title: 'WE-Ticket',
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('ko', 'KR'), // 한국어
          Locale('en', 'US'), // 영어
        ],
        locale: Locale('ko', 'KR'), // 기본 로케일을 한국어로 설정
        home: MainApp(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // ✅ 앱 시작시 초기화 로직
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  /// ✅ 앱 초기화 로직
  Future<void> _initializeApp() async {
    try {
      print('🚀 앱 초기화 시작');

      // 1. AuthProvider의 로그인 상태 확인
      final authProvider = context.read<AuthProvider>();
      await authProvider.checkAuthStatus();

      // 2. 로그인 상태인 경우 초기 데이터 로드
      if (authProvider.isLoggedIn) {
        final apiProvider = context.read<ApiProvider>();
        await apiProvider.loadDashboardData();
        print('✅ 로그인 사용자 초기 데이터 로드 완료');
      }

      print('✅ 앱 초기화 완료');
    } catch (e) {
      print('❌ 앱 초기화 실패: $e');
      // 초기화 실패해도 앱은 정상 실행
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScreen();
  }
}
