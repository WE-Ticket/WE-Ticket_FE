import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/core/constants/app_colors.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/features/auth/presentation/screens/omnione_cx_auth_screen.dart';

class MyAuthScreen extends StatelessWidget {
  final Map<String, int> _authLevelOrder = {
    'none': 0,
    'general': 1,
    'mobile_id': 2,
    'mobile_id_totally': 3,
  };

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final String authLevel = user?.userAuthLevel ?? 'none';
    final String userName = user?.userName ?? '사용자';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '내 인증 관리',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentStatusCard(authLevel, userName, context),
            SizedBox(height: 24),
            _buildUpgradeOptions(authLevel, context),
            SizedBox(height: 24),
            _buildAuthLevelGuide(authLevel),
            SizedBox(height: 24),
            _buildBenefitsSection(),
            SizedBox(height: 24),
            _buildSecurityNotice(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(
    String level,
    String userName,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getAuthLevelColor(level).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getAuthLevelIcon(level),
                  color: _getAuthLevelColor(level),
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName 님의 인증 현황',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getAuthLevelColor(level),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getAuthLevelText(level),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      _getAuthLevelDescription(level),
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
          SizedBox(height: 20),
          _buildPrivileges(level),
        ],
      ),
    );
  }

  Widget _buildPrivileges(String level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이용 가능한 서비스',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        _buildPrivilege('공연 예매', _isAtLeast(level, 'general')),
        _buildPrivilege('3초 간편입장', _isAtLeast(level, 'mobile_id')),
        _buildPrivilege('양도 거래', _isAtLeast(level, 'mobile_id_totally')),
      ],
    );
  }

  Widget _buildPrivilege(String title, bool available) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: available ? AppColors.success : AppColors.gray300,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: available
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeOptions(String level, BuildContext context) {
    if (level == 'mobile_id_totally') {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.verified, color: AppColors.success, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '완전 인증 회원 완료',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    '모든 WE-Ticket 서비스를 자유롭게 이용하실 수 있습니다',
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '인증 업그레이드',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () => _navigateToAuth(context, level),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getUpgradeColor(level).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getUpgradeColor(level).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getUpgradeIcon(level),
                    color: _getUpgradeColor(level),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getUpgradeTitle(level),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getUpgradeDescription(level),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: _getUpgradeColor(level),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthLevelGuide(String currentLevel) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인증 등급 안내',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildLevelItem(
            'general',
            '일반 인증 회원',
            '휴대폰 또는 간편인증으로 기본 티켓 구매',
            AppColors.info,
            currentLevel,
          ),
          SizedBox(height: 12),
          _buildLevelItem(
            'mobile_id',
            '모바일 신분증 인증 회원',
            '모바일신분증으로 강화된 보안과 3초 간편입장',
            AppColors.primary,
            currentLevel,
          ),
          SizedBox(height: 12),
          _buildLevelItem(
            'mobile_id_totally',
            '완전 인증 회원',
            '모든 서비스 이용 가능 및 안전한 양도 거래',
            AppColors.success,
            currentLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelItem(
    String level,
    String title,
    String desc,
    Color color,
    String currentLevel,
  ) {
    final isCurrent = level == currentLevel;
    final isHigher = _authLevelOrder[level]! > _authLevelOrder[currentLevel]!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? color.withOpacity(0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? color : AppColors.gray300,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrent ? color : AppColors.gray300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                (_authLevelOrder[level]).toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrent)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '현재',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  desc,
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
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '회원 등급별 혜택',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildBenefit(Icons.shopping_cart, '안전한 티켓 거래', '일반 인증+'),
          _buildBenefit(Icons.nfc, '3초 간편 입장', '모바일 신분증+'),
          _buildBenefit(Icons.swap_horiz, '자유로운 양도 거래', '완전 인증'),
          _buildBenefit(Icons.shield, '법적 분쟁 보호', '완전 인증'),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String level) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray300.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray400.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '개인정보 보호 안내',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '모든 개인정보는 암호화되어 안전하게 보관되며, 본인인증 목적으로만 사용됩니다. 언제든지 인증 정보를 삭제하거나 수정할 수 있습니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Utility

  bool _isAtLeast(String currentLevel, String requiredLevel) {
    return _authLevelOrder[currentLevel]! >= _authLevelOrder[requiredLevel]!;
  }

  String _getAuthLevelText(String level) =>
      {
        'none': '미인증',
        'general': '일반 인증 회원',
        'mobile_id': '모바일 신분증 인증 회원',
        'mobile_id_totally': '완전 인증 회원',
      }[level] ??
      '알 수 없음';

  String _getAuthLevelDescription(String level) =>
      {
        'none': '서비스 이용을 위해 본인 인증이 필요합니다',
        'general': '휴대폰 또는 간편인증으로 기본 서비스 이용 가능',
        'mobile_id': '모바일신분증 인증으로 강화된 보안 서비스 이용',
        'mobile_id_totally': '모든 서비스 이용 가능한 최고 등급',
      }[level] ??
      '';

  Color _getAuthLevelColor(String level) =>
      {
        'none': AppColors.gray600,
        'general': AppColors.info,
        'mobile_id': AppColors.primary,
        'mobile_id_totally': AppColors.success,
      }[level] ??
      AppColors.gray600;

  IconData _getAuthLevelIcon(String level) =>
      {
        'none': Icons.person_outline,
        'general': Icons.verified_user,
        'mobile_id': Icons.credit_card,
        'mobile_id_totally': Icons.diamond,
      }[level] ??
      Icons.help_outline;

  String _getUpgradeTitle(String level) =>
      {
        'none': '본인 인증하러 가기',
        'general': '모바일 신분증 인증 회원 되기',
        'mobile_id': '완전 인증 회원 되기',
      }[level] ??
      '';

  String _getUpgradeDescription(String level) =>
      {
        'none': '간편인증 또는 모바일 신분증으로 안전하게 인증하세요',
        'general': '모바일신분증으로 인증하고 3초 간편입장을 경험하세요',
        'mobile_id': '추가 인증으로 양도 거래를 통한 더 즐거운 공연을 누리세요',
      }[level] ??
      '';

  Color _getUpgradeColor(String level) => _getAuthLevelColor(level);
  IconData _getUpgradeIcon(String level) => _getAuthLevelIcon(level);

  void _navigateToAuth(BuildContext context, String currentLevel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OmniOneCXAuthScreen(
          currentAuthLevel: _authLevelOrder[currentLevel] ?? 0,
        ),
      ),
    );
  }
}
