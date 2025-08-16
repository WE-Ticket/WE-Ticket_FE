import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/auth_level_entities.dart';

/// 인증 업그레이드 옵션을 보여주는 카드 위젯
class AuthUpgradeCard extends StatelessWidget {
  final AuthUpgradeOption? upgradeOption;
  final VoidCallback? onUpgradeTap;

  const AuthUpgradeCard({
    super.key,
    required this.upgradeOption,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (upgradeOption == null) {
      return _buildCompletedCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '인증 업그레이드',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onUpgradeTap,
          child: _buildUpgradeCard(),
        ),
      ],
    );
  }

  Widget _buildCompletedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.success, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
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

  Widget _buildUpgradeCard() {
    final option = upgradeOption!;
    final color = _getUpgradeColor(option.targetLevel);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
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
            child: Icon(
              _getUpgradeIcon(option.targetLevel),
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (option.benefits.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: option.benefits
                        .map((benefit) => _buildBenefitChip(benefit))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 20,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitChip(String benefit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        benefit,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Color _getUpgradeColor(AuthLevel level) {
    switch (level) {
      case AuthLevel.none:
        return AppColors.gray600;
      case AuthLevel.general:
        return AppColors.info;
      case AuthLevel.mobileId:
        return AppColors.primary;
    }
  }

  IconData _getUpgradeIcon(AuthLevel level) {
    switch (level) {
      case AuthLevel.none:
        return Icons.person_outline;
      case AuthLevel.general:
        return Icons.verified_user;
      case AuthLevel.mobileId:
        return Icons.credit_card;
    }
  }
}