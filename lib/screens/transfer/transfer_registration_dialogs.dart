import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';

class TransferRegistrationDialogs {
  // 양도 등록 확인 및 완료 팝업
  static void showTransferRegistrationDialog(
    BuildContext context,
    Map<String, dynamic> ticket,
    String transferType,
    Function(Map<String, dynamic>, String, String?) onRegister,
  ) {
    bool isLoading = false;
    String? generatedCode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

                //FIXME
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
                    onRegister,
                    setState,
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
            color: AppColors.success.withOpacity(0.1),
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
    Function(Map<String, dynamic>, String, String?) onRegister,
    StateSetter setState,
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
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('취소'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleRegistration(
                  context,
                  ticket,
                  transferType,
                  onRegister,
                  setState,
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

  // 티켓 정보 컨테이너
  static Widget _buildTicketInfoContainer(Map<String, dynamic> ticket) {
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
            ticket['concertTitle'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${ticket['date']} ${ticket['time']}',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            ticket['seat'],
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
                '${_formatPrice(ticket['originalPrice'])}원',
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
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
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
    Function(Map<String, dynamic>, String, String?) onRegister,
    StateSetter setState,
  ) async {
    setState(() {
      // 로딩 상태로 변경하려면 상위 StatefulBuilder에서 관리해야 함
    });

    // 등록 시뮬레이션
    await Future.delayed(Duration(seconds: 2));

    String? generatedCode;
    if (transferType == 'private') {
      generatedCode =
          'PRIV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 11)}-TCKT-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
    }

    // 등록 완료 처리
    onRegister(ticket, transferType, generatedCode);

    setState(() {
      // 완료 상태로 변경
    });
  }

  // 유틸리티 메서드들
  static String _formatPrice(int price) {
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
