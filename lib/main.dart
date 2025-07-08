import 'package:flutter/material.dart';
import 'package:we_ticket/screens/contents/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'WE-Ticket', home: DashboardScreen());
  }
}
