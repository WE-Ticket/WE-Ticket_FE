import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../../data/user_models.dart';

class AuthGuard {
  /// 로그인이 필요한 기능에 접근할 때 호출
  static void requireAuth(
    BuildContext context, {
    required VoidCallback onAuthenticated,
    String? message,
  }) {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isLoggedIn) {
      // 이미 로그인된 상태 → 바로 실행
      onAuthenticated();
    } else {
      // 로그인되지 않은 상태 → 로그인 화면으로 이동
      _showLoginScreen(context, onAuthenticated, message);
    }
  }

  /// 로그인 화면을 표시하고 성공 시 원래 동작 실행
  static void _showLoginScreen(
    BuildContext context,
    VoidCallback onAuthenticated,
    String? message,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          onLoginSuccess: () {
            // 로그인 성공 후 원래 하려던 동작 실행
            Navigator.pop(context);
            onAuthenticated();
          },
        ),
      ),
    );

    // 로그인이 필요하다는 메시지 표시
    if (message != null) {
      Future.delayed(Duration(milliseconds: 300), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.secondaryLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  /// 로그인 상태 확인만 (UI 변경용)
  static bool isLoggedIn(BuildContext context) {
    return context.read<AuthProvider>().isLoggedIn;
  }

  /// 현재 사용자 정보 가져오기
  static UserModel? getCurrentUser(BuildContext context) {
    return context.read<AuthProvider>().user;
  }
}
