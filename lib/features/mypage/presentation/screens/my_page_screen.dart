import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/auth/data/user_models.dart';
import 'package:we_ticket/features/auth/presentation/screens/auth_management_screen.dart';
import 'package:we_ticket/features/contents/presentation/screens/dashboard_screen.dart';
import 'package:we_ticket/features/mypage/presentation/screens/my_tickets_screen.dart';
import 'package:we_ticket/features/mypage/presentation/screens/purchase_history_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('로그아웃이 완료되었습니다.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
          '마이페이지',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserProfileSection(context, user),

                  SizedBox(height: 24),

                  _buildMenuCardsSection(context),

                  SizedBox(height: 24),

                  _buildInquirySection(context),

                  SizedBox(height: 24),

                  _buildLogoutButton(context),

                  SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 사용자 프로필 영역
  // FIXME 인증별 네이밍이나 색상을 상수로 관리하기
  Widget _buildUserProfileSection(BuildContext context, UserModel? user) {
    final authLevel = user?.userAuthLevel ?? 'none';
    final authLevelName = AuthProvider.getAuthLevelName(authLevel);

    // 인증 색상 매핑
    final Map<String, Color> levelColor = {
      'none': AppColors.gray500,
      'general': AppColors.info,
      'mobile_id': AppColors.primary,
      'mobile_id_totally': AppColors.success,
    };
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 프로필 이미지
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.emoji_emotions, size: 50, color: AppColors.white),
          ),

          SizedBox(height: 16),

          Text(
            '${user?.userName} 님 안녕하세요!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 8),

          // 인증 상태 배지
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AuthManagementScreen()),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: levelColor[authLevel]?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 16,
                    color: levelColor[authLevel],
                  ),
                  SizedBox(width: 4),
                  Text(
                    '$authLevelName 회원',
                    style: TextStyle(
                      fontSize: 12,
                      color: levelColor[authLevel],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 4),

          Text(
            '@${user?.loginId ?? 'unknown'}',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // 메뉴 카드 그리드
  Widget _buildMenuCardsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '서비스 이용',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                icon: Icons.account_circle_outlined,
                title: '본인 인증 관리',
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuthManagementScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMenuCard(
                icon: Icons.confirmation_number,
                title: '내 티켓 관리',
                color: AppColors.info,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyTicketsScreen()),
                  );
                },
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                icon: Icons.history,
                title: '구매 이력',
                color: AppColors.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PurchaseHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMenuCard(
                icon: Icons.settings,
                title: '설정 및 계정 관리',
                color: AppColors.secondary,
                onTap: () {
                  // TODO: 설정 및 계정 관리 화면으로 이동
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('설정 및 계정 관리 기능은 추후 구현 예정')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 개별 메뉴 카드
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),

            SizedBox(height: 12),

            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 1:1 문의 섹션
  Widget _buildInquirySection(BuildContext context) {
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primary,
              size: 24,
            ),
          ),

          SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1:1 문의',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '궁금한 점이 있으시면 문의 주세요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              // TODO: 1:1 문의 화면으로 이동
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('문의 기능은 추후 구현 예정')));
            },
            child: Container(
              margin: EdgeInsets.only(left: 10),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '문의하기',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 로그아웃 버튼
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: Icon(Icons.logout, color: AppColors.error),
        label: Text(
          '로그아웃',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('로그아웃'),
        content: Text('정말로 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => DashboardScreen()),
                (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('로그아웃', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}
