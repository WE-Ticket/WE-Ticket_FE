import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:we_ticket/core/utils/app_logger.dart';
import 'package:we_ticket/core/network/dio_client.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/features/auth/presentation/screens/login_screen.dart';
import 'package:we_ticket/features/auth/auth_dependencies.dart';
import 'package:we_ticket/features/contents/presentation/screens/dashboard_screen.dart';
import 'package:we_ticket/features/contents/presentation/providers/contents_provider.dart';
import 'package:we_ticket/features/contents/data/performance_service.dart';
import 'package:we_ticket/features/transfer/presentation/providers/transfer_provider.dart';
import 'package:we_ticket/injection/injection_container.dart';
import 'package:we_ticket/shared/presentation/providers/api_provider.dart';
import 'package:we_ticket/shared/presentation/widgets/app_snackbar.dart';

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

  // 글로벌 네비게이터 키
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        navigatorKey: navigatorKey, // 글로벌 네비게이터 키 설정
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
      AppLogger.info('🚀 앱 초기화 시작', 'MAIN');

      // 1. 글로벌 인증 만료 콜백 설정
      DioClient.setAuthExpiredCallback(_handleAuthExpired);

      // 2. AuthProvider의 로그인 상태 확인
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        await authProvider.checkAuthStatus();

        // 3. 로그인 상태인 경우 초기 데이터 로드
        if (authProvider.isLoggedIn && mounted) {
          final apiProvider = context.read<ApiProvider>();
          await apiProvider.loadDashboardData();
          AppLogger.success('✅ 로그인 사용자 초기 데이터 로드 완료', 'MAIN');
        }
      }

      AppLogger.success('✅ 앱 초기화 완료', 'MAIN');
    } catch (e) {
      AppLogger.error('❌ 앱 초기화 실패', e, null, 'MAIN');
      // 초기화 실패해도 앱은 정상 실행
    }
  }

  /// 글로벌 인증 만료 처리
  void _handleAuthExpired(bool isSessionExpired, bool isConcurrentLogin, String? errorMessage) {
    AppLogger.warning('인증 만료 감지: 세션만료=$isSessionExpired, 동시접속=$isConcurrentLogin', 'AUTH');
    
    // 현재 컨텍스트 확인
    final currentContext = MyApp.navigatorKey.currentContext;
    if (currentContext != null && mounted) {
      // 적절한 토스트 메시지 표시
      String message;
      if (isConcurrentLogin) {
        message = '다른 곳에서 로그인이 감지되었습니다';
      } else {
        message = '로그인 세션이 만료되었습니다';
      }
      
      AppSnackBar.showWarning(currentContext, message);
      
      // AuthProvider를 통한 자동 로그아웃
      final authProvider = Provider.of<AuthProvider>(currentContext, listen: false);
      authProvider.handleAuthExpired(isSessionExpired, isConcurrentLogin, errorMessage);
      
      // 강제 UI 새로고침을 위한 추가 처리
      Future.delayed(Duration(milliseconds: 50), () {
        if (MyApp.navigatorKey.currentContext != null) {
          // 모든 스낵바 제거
          ScaffoldMessenger.of(MyApp.navigatorKey.currentContext!).clearSnackBars();
          
          // 강제로 전체 앱 리빌드 (극단적이지만 확실한 방법)
          final newAuthProvider = Provider.of<AuthProvider>(MyApp.navigatorKey.currentContext!, listen: false);
          if (!newAuthProvider.isLoggedIn) {
            AppLogger.success('✅ 자동 로그아웃 및 UI 새로고침 완료', 'AUTH');
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 로그인 상태에 따라 화면 분기
        if (authProvider.isLoggedIn) {
          return DashboardScreen();
        } else {
          return LoginScreen(
            onLoginSuccess: () {
              // 로그인 성공 시 대시보드로 자동 이동 (Consumer가 자동으로 처리)
            },
          );
        }
      },
    );
  }
}
