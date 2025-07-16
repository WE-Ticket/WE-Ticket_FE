import 'package:flutter/material.dart';
import 'package:we_ticket/features/auth/presentation/screens/omnione_cx_auth_screen.dart';
import 'package:we_ticket/core/constants/app_colors.dart';

class MyAuthScreen extends StatefulWidget {
  @override
  _MyAuthScreenState createState() => _MyAuthScreenState();
}

class _MyAuthScreenState extends State<MyAuthScreen> {
  // FIXME 현재 사용자의 인증 레벨 (실제로는 서버에서 받아올 데이터)
  int currentAuthLevel = 0; // 0: 미인증, 1: 일반 인증, 2: 안전 인증, 3: 완전 인증
  String userName = "정혜교";
  DateTime? lastVerified;

  @override
  Widget build(BuildContext context) {
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
            _buildCurrentStatusCard(),
            SizedBox(height: 24),
            _buildUpgradeOptions(),
            SizedBox(height: 24),
            _buildAuthLevelGuide(),
            SizedBox(height: 24),
            _buildBenefitsSection(),
            SizedBox(height: 24),
            _buildSecurityNotice(),
          ],
        ),
      ),
    );
  }

  // 현재 인증 상태 카드
  Widget _buildCurrentStatusCard() {
    String statusText = _getAuthLevelText(currentAuthLevel);
    String statusDescription = _getAuthLevelDescription(currentAuthLevel);
    Color statusColor = _getAuthLevelColor(currentAuthLevel);
    IconData statusIcon = _getAuthLevelIcon(currentAuthLevel);

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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName님의 인증 현황',
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
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    if (statusDescription.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Text(
                        statusDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildCurrentPrivileges(),
        ],
      ),
    );
  }

  // 현재 이용 가능한 서비스
  Widget _buildCurrentPrivileges() {
    List<Map<String, dynamic>> privileges = [
      {'name': '공연 예매', 'available': currentAuthLevel >= 1},
      {'name': '양도 거래', 'available': currentAuthLevel >= 3},
      {'name': '3초 간편입장', 'available': currentAuthLevel >= 2},
    ];

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
        ...privileges
            .map(
              (privilege) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      privilege['available']
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: privilege['available']
                          ? AppColors.success
                          : AppColors.gray300,
                    ),
                    SizedBox(width: 8),
                    Text(
                      privilege['name'],
                      style: TextStyle(
                        fontSize: 13,
                        color: privilege['available']
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  // 인증 업그레이드 옵션
  Widget _buildUpgradeOptions() {
    if (currentAuthLevel >= 3) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
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
        _buildSingleUpgradeCard(),
      ],
    );
  }

  // 단일 업그레이드 카드
  Widget _buildSingleUpgradeCard() {
    String title = _getUpgradeCardTitle();
    String description = _getUpgradeCardDescription();
    IconData icon = _getUpgradeCardIcon();
    Color color = _getUpgradeCardColor();
    VoidCallback onTap = _getUpgradeCardAction();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  // 인증 레벨 가이드
  Widget _buildAuthLevelGuide() {
    return Container(
      width: double.infinity,
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
          _buildAuthLevelItem(
            1,
            '일반 인증 회원',
            '휴대폰 또는 간편인증으로 기본 티켓 구매',
            AppColors.info,
          ),
          SizedBox(height: 12),
          _buildAuthLevelItem(
            2,
            '모바일 신분증 인증 회원',
            '모바일신분증으로 강화된 보안과 3초 간편입장',
            AppColors.primary,
          ),
          SizedBox(height: 12),
          _buildAuthLevelItem(
            3,
            '완전 인증 회원',
            '모든 서비스 이용 가능 및 안전한 양도 거래',
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthLevelItem(
    int level,
    String title,
    String description,
    Color color,
  ) {
    bool isCurrentLevel = level == currentAuthLevel;
    bool isHigherLevel = level > currentAuthLevel;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentLevel ? color.withOpacity(0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentLevel ? color : AppColors.gray300,
          width: isCurrentLevel ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrentLevel ? color : AppColors.gray300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                level.toString(),
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
                    if (isCurrentLevel) ...[
                      SizedBox(width: 8),
                      Container(
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
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isHigherLevel)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  // 혜택 안내 섹션
  Widget _buildBenefitsSection() {
    return Container(
      width: double.infinity,
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
          _buildBenefitItem(Icons.shopping_cart, '안전한 티켓 거래', '일반 인증+'),
          _buildBenefitItem(Icons.nfc, '3초 간편 입장', '모바일 신분증+'),
          _buildBenefitItem(Icons.swap_horiz, '자유로운 양도 거래', '완전 인증'),
          _buildBenefitItem(Icons.shield, '법적 분쟁 보호', '완전 인증'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String level) {
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

  //FIXME 추후 따로 위젯으로 분리
  // 안내 문구
  Widget _buildSecurityNotice() {
    return Container(
      width: double.infinity,
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

  String _getUpgradeCardTitle() {
    switch (currentAuthLevel) {
      case 0:
        return '본인 인증하러 가기';
      case 1:
        return '모바일 신분증 인증 회원 되기';
      case 2:
        return '완전 인증 회원 되기';
      default:
        return '';
    }
  }

  String _getUpgradeCardDescription() {
    switch (currentAuthLevel) {
      case 0:
        return '간편인증 또는 모바일 신분증으로 안전하게 인증하세요';
      case 1:
        return '모바일신분증으로 인증하고 3초 간편입장을 경험하세요';
      case 2:
        return '추가 인증으로 양도 거래를 통한 더 즐거운 공연을 누리세요';
      default:
        return '';
    }
  }

  IconData _getUpgradeCardIcon() {
    switch (currentAuthLevel) {
      case 0:
        return Icons.security;
      case 1:
        return Icons.credit_card;
      case 2:
        return Icons.diamond;
      default:
        return Icons.help;
    }
  }

  Color _getUpgradeCardColor() {
    switch (currentAuthLevel) {
      case 0:
        return AppColors.primary;
      case 1:
        return AppColors.primary;
      case 2:
        return AppColors.success;
      default:
        return AppColors.gray500;
    }
  }

  VoidCallback _getUpgradeCardAction() {
    switch (currentAuthLevel) {
      case 0:
        return _navigateToAuth;
      case 1:
        return _navigateToMobileIdAuth;
      case 2:
        return _navigateToEnhancedAuth;
      default:
        return () {};
    }
  }

  // 인증 레벨별 텍스트, 색상, 아이콘 반환 함수들
  String _getAuthLevelText(int level) {
    switch (level) {
      case 0:
        return '미인증';
      case 1:
        return '일반 인증 회원';
      case 2:
        return '모바일 신분증 인증 회원';
      case 3:
        return '완전 인증 회원';
      default:
        return '알 수 없음';
    }
  }

  String _getAuthLevelDescription(int level) {
    switch (level) {
      case 0:
        return '서비스 이용을 위해 본인 인증이 필요합니다';
      case 1:
        return '휴대폰 또는 간편인증으로 기본 서비스 이용 가능';
      case 2:
        return '모바일신분증 인증으로 강화된 보안 서비스 이용';
      case 3:
        return '모든 서비스 이용 가능한 최고 등급';
      default:
        return '';
    }
  }

  Color _getAuthLevelColor(int level) {
    switch (level) {
      case 0:
        return AppColors.gray600;
      case 1:
        return AppColors.info;
      case 2:
        return AppColors.primary;
      case 3:
        return AppColors.success;
      default:
        return AppColors.gray600;
    }
  }

  IconData _getAuthLevelIcon(int level) {
    switch (level) {
      case 0:
        return Icons.person_outline;
      case 1:
        return Icons.verified_user;
      case 2:
        return Icons.credit_card;
      case 3:
        return Icons.diamond;
      default:
        return Icons.help_outline;
    }
  }

  // 네비게이션 함수들
  void _navigateToAuth() {
    // 미인증자용 - OmniOne CX에서 인증 방법 선택
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OmniOneCXAuthScreen(currentAuthLevel: currentAuthLevel),
      ),
    );
  }

  void _navigateToMobileIdAuth() {
    // 일반 인증자용 - 모바일 신분증 인증만
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OmniOneCXAuthScreen(currentAuthLevel: currentAuthLevel),
      ),
    );
  }

  void _navigateToEnhancedAuth() {
    // TODO: 추가 VC 인증 화면으로 이동
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('추가 VC 인증 화면으로 이동합니다')));
  }
}
