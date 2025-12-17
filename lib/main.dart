import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';
import 'package:we_ticket/core/constants/app_colors.dart';
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

  // ⭐ 디버그 빨간 에러 화면 대체 (전역 설정)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // 완전 숨기기
    // return const SizedBox.shrink();

    // 필요하면 깔끔한 대체 UI
    return const Material(child: Center(child: Text('로딩 중')));
  };

  // ⭐ 프레임워크 에러: 콘솔에만 기록(원하면 Sentry 등 연동)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // ⭐ 비동기/존재하지 않는 Zone 에러도 잡기 (빨간화면 방지)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    // 원하는 로깅으로 교체 가능
    // ignore: avoid_print
    print('Uncaught async error: $error\n$stack');
    return true; // 에러 전파 막음(빨간 화면 X)
  };

  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      final androidPlatform = AndroidWebViewPlatform();
      WebViewPlatform.instance = androidPlatform;
      AppLogger.success(
        'Android WebView Platform initialized with optimizations',
        'MAIN',
      );
    } catch (e) {
      AppLogger.error('Failed to initialize WebView Platform', e, null, 'MAIN');
    }
  }

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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
          ).copyWith(surface: Colors.white),
          dialogTheme: const DialogThemeData(
            // ← 여기!
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent, // 완전한 흰색
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
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
