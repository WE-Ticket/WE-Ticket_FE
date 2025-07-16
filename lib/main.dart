import 'package:flutter/material.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ApiProvider()),
        ChangeNotifierProvider(
          create: (context) => TransferProvider(
            Provider.of<ApiProvider>(context, listen: false).apiService,
          ),
        ),
      ],
      child: MaterialApp(title: 'WE-Ticket', home: MainApp()),
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
