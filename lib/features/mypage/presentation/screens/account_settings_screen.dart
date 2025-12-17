import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/presentation/widgets/app_snackbar.dart';
import '../../../../shared/presentation/widgets/app_dialog.dart';
import '../../../../shared/presentation/providers/api_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/screens/change_password_screen.dart';
import '../../../contents/presentation/screens/dashboard_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '설정 및 계정 관리',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoSection(context),
              SizedBox(height: 24),
              _buildAccountSection(context),
              SizedBox(height: 24),
              _buildAppInfoSection(context),
              SizedBox(height: 24),
              _buildDangerZoneSection(context),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '계정 정보',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              _buildInfoRow('사용자명', user?.userName ?? '-'),
              SizedBox(height: 12),
              _buildInfoRow('로그인 ID', user?.loginId ?? '-'),
              SizedBox(height: 12),
              _buildInfoRow(
                '인증 등급',
                AuthProvider.getAuthLevelName(user?.userAuthLevel ?? 'none'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '계정 설정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildMenuTile(
            icon: Icons.lock_outline,
            title: '비밀번호 변경',
            subtitle: '로그인 비밀번호를 변경할 수 있습니다.',
            onTap: () {
              final authProvider = context.read<AuthProvider>();
              if (authProvider.user?.loginId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordScreen(
                      currentUserId: authProvider.user!.loginId,
                    ),
                  ),
                );
              } else {
                AppSnackBar.showError(context, '사용자 정보를 불러올 수 없습니다.');
              }
            },
          ),
          // Divider(height: 24, color: AppColors.gray200),
          // _buildMenuTile(
          //   icon: Icons.notifications_outlined,
          //   title: '알림 설정',
          //   subtitle: '푸시 알림 및 이메일 알림 설정',
          //   onTap: () {
          //     AppSnackBar.showInfo(context, '알림 설정 기능은 추후 구현 예정입니다.');
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '약관 및 정책',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildMenuTile(
            icon: Icons.description_outlined,
            title: '서비스 이용약관',
            subtitle: 'WE-Ticket 서비스 이용약관',
            onTap: () {
              AppSnackBar.showInfo(context, '서비스 이용약관 보기 기능은 추후 구현 예정입니다.');
            },
          ),
          Divider(height: 24, color: AppColors.gray200),
          _buildMenuTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보 처리방침',
            subtitle: '개인정보 수집 및 이용에 관한 정책',
            onTap: () {
              AppSnackBar.showInfo(context, '개인정보 처리방침 보기 기능은 추후 구현 예정입니다.');
            },
          ),
          Divider(height: 24, color: AppColors.gray200),
          _buildMenuTile(
            icon: Icons.info_outline,
            title: '앱 정보',
            subtitle: '버전: 1.0.0',
            onTap: () {
              _showAppInfoDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Icon(Icons.warning_outlined, color: AppColors.error, size: 20),
          //     SizedBox(width: 8),
          //     Text(
          //       '위험 구역',
          //       style: TextStyle(
          //         fontSize: 18,
          //         fontWeight: FontWeight.bold,
          //         color: AppColors.error,
          //       ),
          //     ),
          //   ],
          // ),
          // SizedBox(height: 16),
          _buildMenuTile(
            icon: Icons.delete_forever_outlined,
            title: '회원 탈퇴',
            subtitle: '계정 및 모든 데이터가 영구적으로 삭제됩니다.',
            titleColor: AppColors.error,
            onTap: () {
              _showDeleteAccountDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (titleColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: titleColor ?? AppColors.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('WE-Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('버전: 1.0.0'),
            SizedBox(height: 8),
            Text('NFT 기반 티켓 거래 플랫폼'),
            SizedBox(height: 8),
            Text('© 2024 WE-Ticket. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final pageContext = context;
    final passwordController = TextEditingController();

    AppDialog.showChoice(
      context: pageContext,
      title: '회원 탈퇴',
      message:
          '정말로 회원 탈퇴하시겠습니까?\n\n'
          '• 모든 개인정보가 삭제됩니다\n'
          '• 보유 중인 티켓이 모두 소실됩니다\n'
          '• 거래 내역이 모두 삭제됩니다\n'
          '• 이 작업은 되돌릴 수 없습니다',
      icon: Icons.warning,
      iconColor: AppColors.error,
      confirmText: '탈퇴하기',
      cancelText: '취소',
    ).then((confirmed) {
      if (confirmed == true) {
        _showPasswordInputDialog(pageContext, passwordController);
      }
    });
  }

  void _showPasswordInputDialog(
    BuildContext context,
    TextEditingController passwordController,
  ) {
    final pageContext = context;

    showDialog(
      context: pageContext,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Text('비밀번호 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('회원 탈퇴를 위해 현재 비밀번호를 입력해주세요.'),
            SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '현재 비밀번호',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final pw = passwordController.text.trim();
              if (pw.isEmpty) {
                AppSnackBar.showError(pageContext, '비밀번호를 입력해주세요.');
                return;
              }
              Navigator.pop(dialogCtx);
              _processDeleteAccount(pageContext, pw);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text('탈퇴하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _processDeleteAccount(
    BuildContext context,
    String password,
  ) async {
    try {
      final apiProvider = context.read<ApiProvider>();

      final result = await AuthService(
        apiProvider.dioClient,
      ).deleteAccount(password: password);

      if (!context.mounted) return;

      if (result.isSuccess) {
        AppSnackBar.showError(context, '회원 탈퇴가 완료되었습니다.');

        // 1) 앱 상태를 먼저 완전히 비우기
        await _logoutEverywhere(context);

        if (!context.mounted) return;

        // 2) 루트(대시보드)로 이동
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DashboardScreen()),
          (route) => false,
        );
      } else {
        String errorMessage = result.errorMessage ?? '회원 탈퇴에 실패했습니다.';
        if (result.statusCode == 400) {
          errorMessage = '현재 비밀번호가 올바르지 않습니다.';
        } else if (result.statusCode == 401) {
          errorMessage = '인증이 만료되었습니다. 다시 로그인해주세요.';
        }
        AppSnackBar.showError(context, errorMessage);
      }
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showError(context, '회원 탈퇴 처리 중 오류가 발생했습니다.');
    }
  }

  Future<void> _logoutEverywhere(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    await authProvider.logout();

    // 3) SharedPreferences 클리어
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }
}
