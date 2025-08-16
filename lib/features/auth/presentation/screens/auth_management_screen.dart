import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/presentation/providers/api_provider.dart';
import '../../domain/entities/auth_level_entities.dart';
import '../providers/auth_level_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/did_provider.dart';
import '../widgets/auth_status_card.dart';
import '../widgets/auth_upgrade_card.dart';
import '../widgets/did_creation_dialog.dart';
import '../widgets/auth_method_selection_dialog.dart';
import '../widgets/additional_auth_explanation_dialog.dart';
import 'omnione_cx_auth_screen.dart';

class AuthManagementScreen extends StatefulWidget {
  const AuthManagementScreen({super.key});

  @override
  State<AuthManagementScreen> createState() => _AuthManagementScreenState();
}

class _AuthManagementScreenState extends State<AuthManagementScreen> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authProvider = context.read<AuthProvider>();
    final authLevelProvider = context.read<AuthLevelProvider>();

    final userId = authProvider.currentUserId;
    if (userId != null) {
      await authLevelProvider.loadUserAuthLevel(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
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
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<AuthLevelProvider>(
          builder: (context, authLevelProvider, child) {
            return IconButton(
              icon: authLevelProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.refresh, color: AppColors.textPrimary),
              onPressed: authLevelProvider.isLoading ? null : _refreshAuthLevel,
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer3<AuthProvider, AuthLevelProvider, DidProvider>(
      builder: (context, authProvider, authLevelProvider, didProvider, child) {
        final user = authProvider.user;
        final userName = user?.userName ?? '사용자';

        if (authLevelProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (authLevelProvider.errorMessage != null) {
          return _buildErrorState(authLevelProvider.errorMessage!);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthStatusCard(
                authLevel: authLevelProvider.currentLevel,
                userName: userName,
                privileges: authLevelProvider.privileges,
              ),
              const SizedBox(height: 24),
              AuthUpgradeCard(
                upgradeOption: authLevelProvider.upgradeOption,
                onUpgradeTap: () => _handleUpgradeRequest(
                  context,
                  authLevelProvider.currentLevel,
                ),
              ),
              const SizedBox(height: 24),
              _buildAuthLevelGuide(authLevelProvider.currentLevel),
              const SizedBox(height: 24),
              _buildBenefitsSection(),
              const SizedBox(height: 24),
              _buildSecurityNotice(),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshAuthLevel,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAuthLevel() async {
    final authProvider = context.read<AuthProvider>();
    final authLevelProvider = context.read<AuthLevelProvider>();

    final userId = authProvider.currentUserId;
    if (userId != null) {
      await authLevelProvider.loadUserAuthLevel(userId);
    }
  }

  Future<void> _handleUpgradeRequest(
    BuildContext context,
    AuthLevel currentLevel,
  ) async {
    switch (currentLevel) {
      case AuthLevel.none:
        await _handleNoneToGeneralUpgrade(context);
        break;
      case AuthLevel.general:
        await _handleGeneralToMobileIdUpgrade(context);
        break;
      case AuthLevel.mobileId:
        _showSuccess('이미 최고 등급입니다.');
        break;
    }
  }

  /// none → general 업그레이드 (인증 방법 선택)
  Future<void> _handleNoneToGeneralUpgrade(BuildContext context) async {
    final selectedMethod = await showDialog<String>(
      context: context,
      builder: (context) => const AuthMethodSelectionDialog(),
    );

    if (selectedMethod != null && mounted) {
      await _navigateToAuth(context, AuthLevel.general, selectedMethod);
    }
  }

  /// general → mobile_id 업그레이드 (추가 인증 설명)
  Future<void> _handleGeneralToMobileIdUpgrade(BuildContext context) async {
    final userAgreed = await showDialog<bool>(
      context: context,
      builder: (context) => const AdditionalAuthExplanationDialog(),
    );

    if (userAgreed == true && mounted) {
      await _navigateToAuth(context, AuthLevel.mobileId, 'mobile_id');
    }
  }

  Future<void> _navigateToAuth(
    BuildContext context,
    AuthLevel targetLevel,
    String authMethod,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;

    if (userId == null) {
      _showError('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.');
      return;
    }

    // OmniOne 인증 화면으로 이동
    final apiProvider = context.read<ApiProvider>();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => OmniOneCXAuthScreen(
          userId: userId,
          currentAuthLevel: targetLevel.order,
          authService: apiProvider.authService,
          authMethod: authMethod,
        ),
      ),
    );

    // 인증 결과 처리
    if (result != null && result['success'] == true) {
      await _handleAuthSuccess(result);
    }
  }

  Future<void> _handleAuthSuccess(Map<String, dynamic> result) async {
    final authLevelProvider = context.read<AuthLevelProvider>();
    final didProvider = context.read<DidProvider>();
    final authProvider = context.read<AuthProvider>();

    try {
      // 1. 인증 레벨 새로고침
      final userId = authProvider.currentUserId;
      if (userId != null) {
        await authLevelProvider.loadUserAuthLevel(userId);
      }

      // 2. DID 생성 플로우 시작
      await _startDidCreationFlow(didProvider, userId!);

      // 3. 성공 메시지 표시
      _showSuccess('본인인증이 완료되었습니다!');
    } catch (e) {
      AppLogger.error('인증 성공 처리 오류', e, null, 'AUTH');
      _showError('인증 처리 중 오류가 발생했습니다.');
    }
  }

  Future<void> _startDidCreationFlow(
    DidProvider didProvider,
    int userId,
  ) async {
    // DID 생성 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<DidProvider>(
        builder: (context, provider, child) {
          return DidCreationDialog(progress: provider.progress);
        },
      ),
    );

    // DID 생성 및 등록 실행
    final success = await didProvider.createAndRegisterDid(userId: userId);

    // 다이얼로그 닫기
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (!success && didProvider.errorMessage != null) {
      _showError(didProvider.errorMessage!);
    }
  }

  Widget _buildAuthLevelGuide(AuthLevel currentLevel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '인증 등급 안내',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildLevelItem(
            AuthLevel.general,
            '일반 인증 회원',
            '간편인증 또는 모바일신분증으로 공연 예매 및 간편 입장 서비스 이용이 가능합니다.',
            AppColors.info,
            currentLevel,
          ),
          const SizedBox(height: 12),
          _buildLevelItem(
            AuthLevel.mobileId,
            '안전 인증 회원',
            '모바일신분증 추가 인증으로 양도 거래 서비스까지 안전하게 이용 가능합니다.',
            AppColors.primary,
            currentLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelItem(
    AuthLevel level,
    String title,
    String desc,
    Color color,
    AuthLevel currentLevel,
  ) {
    final isCurrent = level == currentLevel;

    return Container(
      padding: const EdgeInsets.all(16),
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
                level.order.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrent)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
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
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '회원 등급별 혜택',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefit(Icons.shopping_cart, '안전한 티켓 예매', '일반 인증+'),
          _buildBenefit(Icons.nfc, '3초 간편 입장', '일반 인증+'),
          _buildBenefit(Icons.swap_horiz, '자유로운 양도 거래', '안전 인증+'),
          _buildBenefit(Icons.shield, '법적 분쟁 보호', '안전 인증+'),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String level) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level,
              style: const TextStyle(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray300.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray400.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '개인정보 보호 안내',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryDark,
                  ),
                ),
                const SizedBox(height: 4),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }
}
