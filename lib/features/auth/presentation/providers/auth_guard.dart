import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/core/constants/app_colors.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/features/auth/presentation/screens/login_screen.dart';
import 'package:we_ticket/features/auth/data/user_models.dart';
import 'package:we_ticket/features/mypage/presentation/screens/my_auth_screen.dart';

class AuthGuard {
  /// 예매하기 버튼용 - 로그인 + 인증 레벨 확인
  static void requireAuthForTicketing(
    BuildContext context, {
    required VoidCallback onAuthenticated,
    String? message,
  }) {
    final authProvider = context.read<AuthProvider>();

    // 1. 로그인 여부 확인
    if (!authProvider.isLoggedIn) {
      _showLoginRequiredDialog(context, onAuthenticated, message);
      return;
    }

    // 2. 인증 레벨 확인 (general 이상이어야 함)
    final user = authProvider.user;
    if (user == null || user.userAuthLevel == 'none') {
      _showAuthLevelRequiredDialog(context, onAuthenticated);
      return;
    }

    // 3. 모든 조건 만족 시 예매 진행
    onAuthenticated();
  }

  /// 일반 로그인이 필요한 기능에 접근할 때 호출
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

  /// 특정 인증 레벨이 필요한 기능 확인
  static void requireAuthLevel(
    BuildContext context, {
    required String requiredLevel,
    required VoidCallback onAuthenticated,
    String? message,
  }) {
    final authProvider = context.read<AuthProvider>();

    // 1. 로그인 확인
    if (!authProvider.isLoggedIn) {
      _showLoginRequiredDialog(context, onAuthenticated, message);
      return;
    }

    // 2. 인증 레벨 확인
    final user = authProvider.user;
    if (user == null ||
        !_hasRequiredAuthLevel(user.userAuthLevel, requiredLevel)) {
      _showAuthLevelRequiredDialog(context, onAuthenticated, requiredLevel);
      return;
    }

    // 3. 조건 만족 시 실행
    onAuthenticated();
  }

  // Private methods

  /// 로그인이 필요하다는 다이얼로그 표시
  static void _showLoginRequiredDialog(
    BuildContext context,
    VoidCallback onAuthenticated,
    String? message,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.login, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              '로그인 필요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message ?? '이 서비스를 이용하려면 로그인이 필요합니다.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: AppColors.gray500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showLoginScreen(context, onAuthenticated, null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('로그인'),
          ),
        ],
      ),
    );
  }

  /// 인증 레벨이 부족하다는 다이얼로그 표시
  static void _showAuthLevelRequiredDialog(
    BuildContext context,
    VoidCallback onAuthenticated, [
    String? requiredLevel,
  ]) {
    final authProvider = context.read<AuthProvider>();
    final currentLevel = authProvider.currentUserAuthLevel ?? 'none';
    final currentLevelName = AuthProvider.getAuthLevelName(currentLevel);

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.security, color: AppColors.warning, size: 24),
            SizedBox(width: 8),
            Text(
              '본인 인증 필요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '안전한 티켓 예매를 위해 본인 인증이 필요합니다.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '현재 인증 상태: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        currentLevelName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '필요 인증 상태: 일반 인증 이상',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: AppColors.gray500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyAuthScreen()),
              ).then((_) {
                // 인증 후 돌아왔을 때 다시 확인
                final updatedProvider = context.read<AuthProvider>();
                if (updatedProvider.user?.userAuthLevel != null &&
                    updatedProvider.user!.userAuthLevel != 'none') {
                  onAuthenticated();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('인증하기'),
          ),
        ],
      ),
    );
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

            // 로그인 후 인증 레벨도 다시 확인
            final authProvider = context.read<AuthProvider>();
            final user = authProvider.user;

            if (user?.userAuthLevel == 'none') {
              // 로그인은 됐지만 인증 레벨이 부족한 경우
              _showAuthLevelRequiredDialog(context, onAuthenticated);
            } else {
              // 모든 조건 만족
              onAuthenticated();
            }
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
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  /// 인증 레벨이 요구사항을 만족하는지 확인
  static bool _hasRequiredAuthLevel(
    String? currentLevel,
    String requiredLevel,
  ) {
    if (currentLevel == null) return false;

    // 인증 레벨 우선순위 정의
    const Map<String, int> levelPriority = {
      'none': 0,
      'general': 1,
      'mobile_id': 2,
      'mobile_id_totally': 3,
    };

    final currentPriority = levelPriority[currentLevel] ?? 0;
    final requiredPriority = levelPriority[requiredLevel] ?? 0;

    return currentPriority >= requiredPriority;
  }

  // Utility getters

  /// 로그인 상태 확인만 (UI 변경용)
  static bool isLoggedIn(BuildContext context) {
    return context.read<AuthProvider>().isLoggedIn;
  }

  /// 현재 사용자 정보 가져오기
  static UserModel? getCurrentUser(BuildContext context) {
    return context.read<AuthProvider>().user;
  }

  /// 현재 사용자의 인증 레벨 확인
  static String? getCurrentAuthLevel(BuildContext context) {
    return context.read<AuthProvider>().currentUserAuthLevel;
  }

  /// 예매 가능 여부 확인
  static bool canMakeReservation(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn) return false;

    final user = authProvider.user;
    return user != null && user.userAuthLevel != 'none';
  }

  /// 양도 거래 가능 여부 확인 (mobile_id_totally 레벨 필요)
  static bool canTransferTicket(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn) return false;

    final user = authProvider.user;
    return user != null && user.userAuthLevel == 'mobile_id_totally';
  }

  /// NFC 간편 입장 가능 여부 확인 (mobile_id 이상 필요)
  static bool canUseNFCEntry(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn) return false;

    final user = authProvider.user;
    return user != null &&
        (user.userAuthLevel == 'mobile_id' ||
            user.userAuthLevel == 'mobile_id_totally');
  }
}
