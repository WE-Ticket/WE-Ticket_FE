import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/presentation/providers/api_provider.dart';
import '../../../../shared/presentation/widgets/app_snackbar.dart';
import '../providers/auth_provider.dart';

/// 추가 인증 설명 다이얼로그
/// general 상태에서 mobile_id로 업그레이드할 때 왜 추가 인증이 필요한지 설명
class AdditionalAuthExplanationDialog extends StatefulWidget {
  const AdditionalAuthExplanationDialog({super.key});

  @override
  State<AdditionalAuthExplanationDialog> createState() => _AdditionalAuthExplanationDialogState();
}

class _AdditionalAuthExplanationDialogState extends State<AdditionalAuthExplanationDialog> {
  bool _isSubmitting = false;

  /// 사용자 약관 동의 API 호출
  Future<void> _submitUserAgreement() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final apiProvider = context.read<ApiProvider>();
      
      final userId = authProvider.currentUserId;
      if (userId == null) {
        AppSnackBar.showError(context, '사용자 정보를 찾을 수 없습니다.');
        return;
      }

      // 직접 API 호출
      final requestData = {
        'user_id': userId,
        'term_type': '개인정보_추가수집_동의',
        'agreed_at': DateTime.now().toIso8601String(),
      };

      final response = await apiProvider.apiService.auth.dioClient.post(
        '/users/vc-agreement/',
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          AppSnackBar.showSuccess(context, '개인정보 수집에 동의하였습니다.');
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          AppSnackBar.showError(context, '약관 동의 처리에 실패했습니다.');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '약관 동의 처리 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.security,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              '안전 인증 회원 되기',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              '모바일신분증으로 추가 인증하면\n더 안전하고 다양한 서비스를 이용할 수 있어요',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // 추가 혜택 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '추가로 이용 가능한 서비스',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem('- 안전한 양도 거래', '다른 사용자와 티켓을 안전하게 거래'),
                  _buildBenefitItem('- 강화된 보안', '더욱 안전한 본인 확인 시스템'),
                  _buildBenefitItem('- 법적 분쟁 보호', '거래 과정에서 발생하는 문제 보호'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 개인정보 수집 안내
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '개인정보 추가 수집 동의',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '안전한 양도 거래를 위해 모바일신분증으로 본인 인증을 진행하고 있습니다, \n 모바일 신분증 본인인증으로 추가 신원 정보 (생년월일, 주소) 를 수집합니다.\n 동의를 하셔야 해당 서비스 이용이 가능하며, 언제든 동의를 거부하실 수 있습니다.\n 수집된 정보는 안전하게 보관됩니다.',
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
            ),

            const SizedBox(height: 24),

            // 버튼들
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitUserAgreement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '처리 중...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            '동의하고 인증하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
