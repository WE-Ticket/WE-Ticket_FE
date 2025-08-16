import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/auth_level_entities.dart';

/// 현재 인증 상태를 보여주는 카드 위젯
class AuthStatusCard extends StatelessWidget {
  final AuthLevel authLevel;
  final String userName;
  final List<UserPrivilege> privileges;

  const AuthStatusCard({
    super.key,
    required this.authLevel,
    required this.userName,
    required this.privileges,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPrivileges(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _getAuthLevelColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _getAuthLevelIcon(),
            color: _getAuthLevelColor(),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$userName 님의 인증 현황',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getAuthLevelColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  authLevel.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                authLevel.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivileges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이용 가능한 서비스',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...privileges.map((privilege) => _buildPrivilegeItem(privilege)),
      ],
    );
  }

  Widget _buildPrivilegeItem(UserPrivilege privilege) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            privilege.isAvailable ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: privilege.isAvailable ? AppColors.success : AppColors.gray300,
          ),
          const SizedBox(width: 8),
          Text(
            privilege.name,
            style: TextStyle(
              fontSize: 13,
              color: privilege.isAvailable
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAuthLevelColor() {
    switch (authLevel) {
      case AuthLevel.none:
        return AppColors.gray600;
      case AuthLevel.general:
        return AppColors.info;
      case AuthLevel.mobileId:
        return AppColors.primary;
    }
  }

  IconData _getAuthLevelIcon() {
    switch (authLevel) {
      case AuthLevel.none:
        return Icons.person_outline;
      case AuthLevel.general:
        return Icons.verified_user;
      case AuthLevel.mobileId:
        return Icons.credit_card;
    }
  }
}