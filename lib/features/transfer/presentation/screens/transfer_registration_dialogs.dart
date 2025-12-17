import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/shared/presentation/providers/api_provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';

class TransferRegistrationDialogs {
  // 양도 등록 확인 및 완료 팝업
  static void showTransferRegistrationDialog(
    BuildContext context,
    Map<String, dynamic> ticket,
    String transferType,
  ) {
    bool isLoading = false;
    String? generatedCode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  children: [
                    Icon(
                      transferType == 'private' ? Icons.lock : Icons.public,
                      color: transferType == 'private'
                          ? AppColors.secondary
                          : AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${transferType == 'private' ? '비공개' : '공개'} 양도 등록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Spacer(),
                    if (!isLoading)
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 20),

                // 상태별 내용
                if (isLoading) ...[
                  _buildLoadingState(),
                ] else if (generatedCode != null) ...[
                  _buildCompletedState(context, transferType, generatedCode!),
                ] else ...[
                  _buildConfirmationState(
                    context,
                    ticket,
                    transferType,
                    setState,
                    (loading, code) {
                      setState(() {
                        isLoading = loading;
                        generatedCode = code;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 로딩 상태 위젯
  static Widget _buildLoadingState() {
    return Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
        SizedBox(height: 16),
        Text(
          '양도 등록 중입니다...',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // 완료 상태 위젯
  static Widget _buildCompletedState(
    BuildContext context,
    String transferType,
    String generatedCode,
  ) {
    return Column(
      children: [
        // 완료 아이콘
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(Icons.check, color: AppColors.success, size: 30),
        ),
        SizedBox(height: 16),
        Text(
          '양도 등록이 완료되었습니다!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        // 비공개 양도일 때만 고유번호 표시
        if (transferType == 'private') ...[
          SizedBox(height: 20),
          Text(
            '생성된 고유 번호',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          _buildUniqueCodeContainer(generatedCode),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyUniqueCode(context, generatedCode),
                  icon: Icon(Icons.copy, size: 16),
                  label: Text('복사하기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('확인'),
          ),
        ),
      ],
    );
  }

  // 확인 상태 위젯
  static Widget _buildConfirmationState(
    BuildContext context,
    Map<String, dynamic> ticket,
    String transferType,
    StateSetter setState,
    Function(bool, String?) updateState,
  ) {
    return Column(
      children: [
        // 등록 확인
        Text(
          '다음 티켓을 양도 등록하시겠습니까?',
          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),

        SizedBox(height: 16),

        // 티켓 정보
        _buildTicketInfoContainer(ticket),

        SizedBox(height: 20),

        // 버튼들
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleRegistration(
                  context,
                  ticket,
                  transferType,
                  updateState,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: transferType == 'private'
                      ? AppColors.secondary
                      : AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('등록하기'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 티켓 정보 컨테이너 (안전한 버전)
  static Widget _buildTicketInfoContainer(Map<String, dynamic> ticket) {
    // 안전하게 데이터 추출
    final title = _getSafeString(ticket, [
      'title',
      'concertTitle',
      'performance_title',
    ], '제목 없음');
    final date = _getSafeString(ticket, ['date'], '날짜 미정');
    final time = _getSafeString(ticket, ['time'], '시간 미정');
    final seat = _getSafeString(ticket, ['seat', 'seat_number'], '좌석 미정');
    final price = _getSafePrice(ticket, [
      'originalPrice',
      'price',
      'seat_price',
    ], 0);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$date $time',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            seat,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '양도 가격',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_formatPrice(price)}원',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 고유번호 컨테이너
  static Widget _buildUniqueCodeContainer(String code) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            code,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, size: 16, color: AppColors.warning),
              SizedBox(width: 4),
              Text(
                '24시간 후 자동 만료',
                style: TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 등록 처리 함수
  static Future<void> _handleRegistration(
    BuildContext context,
    Map<String, dynamic> ticket,
    String transferType,
    Function(bool, String?) updateState,
  ) async {
    updateState(true, null);

    try {
      final apiProvider = context.read<ApiProvider>();
      final transferService = apiProvider.apiService.transfer;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // AuthProvider에서 현재 사용자 ID 가져오기
      final userId = authProvider.user?.userId;

      final response = await transferService.postTransferTicketRegister(
        userId: userId,
        ticketId: ticket['ticketId'],
        isPublicTransfer: transferType == 'public',
        transferTicketPrice: ticket['originalPrice'],
      );

      // ✅ 응답 처리
      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? '양도 등록 실패');
      }

      // ✅ 응답에서 코드가 오면 (비공개일 경우)
      String? generatedCode;
      if (transferType == 'private' && response.data != null) {
        generatedCode = response.data!['unique_code']; // 백엔드 반환 키 확인 필요
      }

      // ✅ 등록 완료 상태로 UI 업데이트
      updateState(false, generatedCode);

      Navigator.pop(context);
    } catch (e) {
      print('❌ 양도 등록 오류: $e');
      updateState(false, null);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('양도 등록 중 오류가 발생했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // 안전한 문자열 추출 함수
  static String _getSafeString(
    Map<String, dynamic> data,
    List<String> keys,
    String defaultValue,
  ) {
    for (String key in keys) {
      final value = data[key];
      if (value != null &&
          value.toString().isNotEmpty &&
          value.toString() != 'null') {
        return value.toString();
      }
    }
    return defaultValue;
  }

  // 안전한 가격 추출 함수
  static int _getSafePrice(
    Map<String, dynamic> data,
    List<String> keys,
    int defaultValue,
  ) {
    for (String key in keys) {
      final value = data[key];
      if (value != null) {
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return defaultValue;
  }

  // 유틸리티 메서드들
  static String _formatPrice(int price) {
    if (price <= 0) return '0';
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  static void _copyUniqueCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('고유 번호가 복사되었습니다'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
