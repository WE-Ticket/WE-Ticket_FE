import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:we_ticket/core/utils/app_logger.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/features/auth/auth_dependencies.dart';
import 'package:we_ticket/features/contents/presentation/screens/dashboard_screen.dart';
import 'package:we_ticket/features/contents/presentation/providers/contents_provider.dart';
import 'package:we_ticket/features/contents/data/performance_service.dart';
import 'package:we_ticket/features/transfer/presentation/providers/transfer_provider.dart';
import 'package:we_ticket/features/mypage/mypage_dependencies.dart';
import 'package:we_ticket/injection/injection_container.dart';
import 'package:we_ticket/shared/presentation/providers/api_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      // Android WebView 플랫폼 최적화 설정
      final androidPlatform = AndroidWebViewPlatform();
      WebViewPlatform.instance = androidPlatform;
      AppLogger.success('Android WebView Platform initialized with optimizations', 'MAIN');
    } catch (e) {
      AppLogger.error('Failed to initialize WebView Platform', e, null, 'MAIN');
    }
  }

  // Initialize dependencies
  try {
    await initializeDependencies();
    AppLogger.success('🚀 App starting with Clean Architecture setup', 'MAIN');
  } catch (e) {
    AppLogger.error('Failed to initialize dependencies', e, null, 'MAIN');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        //  1. ApiProvider를 먼저 생성 (DioClient 포함)
        ChangeNotifierProvider(create: (_) => ApiProvider()),

        //  2. AuthProvider는 ApiProvider의 DioClient를 사용
        ChangeNotifierProxyProvider<ApiProvider, AuthProvider>(
          create: (context) {
            final apiProvider = Provider.of<ApiProvider>(
              context,
              listen: false,
            );
            return AuthProvider(apiProvider.dioClient);
          },
          update: (context, apiProvider, previousAuthProvider) {
            return previousAuthProvider ?? AuthProvider(apiProvider.dioClient);
          },
        ),

        // 3. ContentsProvider는 ApiProvider의 DioClient를 사용
        ChangeNotifierProxyProvider<ApiProvider, ContentsProvider>(
          create: (context) {
            final apiProvider = Provider.of<ApiProvider>(
              context,
              listen: false,
            );
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

        //  4. TransferProvider는 ApiProvider에 의존
        ChangeNotifierProxyProvider<ApiProvider, TransferProvider>(
          create: (context) => TransferProvider(
            Provider.of<ApiProvider>(context, listen: false).apiService,
          ),
          update: (context, apiProvider, previousTransferProvider) =>
              previousTransferProvider ??
              TransferProvider(apiProvider.apiService),
        ),

        //  5. 새로운 Clean Architecture Providers
        ...AuthDependencies.getProxyProviders(),

        //  6. MyPage Providers
        ...MyPageDependencies.getProxyProviders(),
      ],
      child: MaterialApp(
        title: 'WE-Ticket',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
        locale: const Locale('ko', 'KR'),
        home: MainApp(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      print('🚀 앱 초기화 시작');

      final authProvider = context.read<AuthProvider>();
      await authProvider.checkAuthStatus();

      if (authProvider.isLoggedIn) {
        final apiProvider = context.read<ApiProvider>();
        await apiProvider.loadDashboardData();
        print('✅ 로그인 사용자 초기 데이터 로드 완료');
      }

      print('✅ 앱 초기화 완료');
    } catch (e) {
      print('❌ 앱 초기화 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScreen();
  }
}
