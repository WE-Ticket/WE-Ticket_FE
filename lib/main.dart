import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/contents/presentation/screens/dashboard_screen.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/features/shared/providers/api_provider.dart';
import 'package:we_ticket/features/transfer/presentation/providers/transfer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider를 먼저 생성
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // 🔧 수정: ApiProvider 생성자 변경 (AuthProvider 의존성 제거)
        ChangeNotifierProvider(create: (_) => ApiProvider()),

        // TransferProvider는 ApiProvider에 의존
        ChangeNotifierProxyProvider<ApiProvider, TransferProvider>(
          create: (context) => TransferProvider(
            Provider.of<ApiProvider>(context, listen: false).apiService,
          ),
          update: (context, apiProvider, previousTransferProvider) =>
              previousTransferProvider ??
              TransferProvider(apiProvider.apiService),
        ),
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
    // 앱 시작시 로그인 상태 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScreen();
  }
}
