import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/shared/providers/api_provider.dart';
import 'package:we_ticket/features/transfer/data/transfer_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/transfer_provider.dart';
import '../../data/transfer_models.dart';

class TransferEditDialogs {
  // 양도 수정 메인 팝업
  static void showEditTransferDialog(
    BuildContext context,
    int transferTicketId,
  ) {
    showDialog(
      context: context,
      builder: (context) => Consumer<TransferProvider>(
        builder: (context, transferProvider, child) {
          // 현재 티켓 정보 찾기
          MyTransferTicket? ticket;
          if (transferProvider.myRegisteredTickets != null) {
            try {
              ticket = transferProvider.myRegisteredTickets!.firstWhere(
                (t) => t.transferTicketId == transferTicketId,
              );
            } catch (e) {
              // 티켓을 찾을 수 없는 경우
            }
          }

          if (ticket == null) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, color: AppColors.error, size: 48),
                    SizedBox(height: 16),
                    Text(
                      '티켓 정보를 찾을 수 없습니다',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('확인'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
                      Icon(Icons.edit, color: AppColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '양도 정보 수정',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Spacer(),
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

                  // 현재 양도 정보
                  _buildCurrentTransferInfo(ticket),

                  SizedBox(height: 20),

                  // 수정 가능한 옵션들
                  Text(
                    '수정할 항목을 선택하세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  SizedBox(height: 12),

                  // 양도 방식 변경 (진행 중이 아닐 때만)
                  if (ticket.canCancel)
                    _buildEditOption(
                      context,
                      icon: Icons.swap_horiz,
                      title: '양도 방식 변경',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        showChangeTransferTypeDialog(context, ticket!);
                      },
                    ),

                  if (!ticket.isPublicTransfer && ticket.canCancel) ...[
                    SizedBox(height: 8),
                    // 고유 번호 재생성
                    _buildEditOption(
                      context,
                      icon: Icons.refresh,
                      title: '고유 번호 재생성',
                      color: AppColors.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        showRegenerateCodeDialog(context, ticket!);
                      },
                    ),
                  ],

                  SizedBox(height: 20),

                  // 취소 버튼
                  SizedBox(
                    width: double.infinity,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 현재 양도 정보 표시
  static Widget _buildCurrentTransferInfo(MyTransferTicket ticket) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ticket.isPublicTransfer ? Icons.public : Icons.lock,
                size: 16,
                color: ticket.isPublicTransfer
                    ? AppColors.primary
                    : AppColors.secondary,
              ),
              SizedBox(width: 8),
              Text(
                ticket.transferTypeText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    ticket.transferStatus,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ticket.statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(ticket.transferStatus),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            ticket.performanceTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${ticket.seatNumber} (${ticket.seatGrade})',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // 수정 옵션 아이템
  static Widget _buildEditOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // 양도 방식 변경 팝업
  static void showChangeTransferTypeDialog(
    BuildContext context,
    MyTransferTicket ticket,
  ) {
    bool currentIsPublic = ticket.isPublicTransfer;
    bool newIsPublic = !currentIsPublic;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;
        String? newGeneratedCode;
        bool isCompleted = false;

        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
                        Icons.swap_horiz,
                        color: AppColors.warning,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '양도 방식 변경',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Spacer(),
                      if (!isLoading)
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                          ),
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

                  if (isLoading) ...[
                    _buildLoadingState('양도 방식을 변경하고 있습니다...'),
                  ] else if (isCompleted) ...[
                    _buildChangeCompletedState(
                      context,
                      newIsPublic,
                      newGeneratedCode,
                      ticket,
                    ),
                  ] else ...[
                    _buildChangeConfirmationState(
                      context,
                      currentIsPublic,
                      newIsPublic,
                      () async {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final apiProvider = context.read<ApiProvider>();
                          final transferService =
                              apiProvider.apiService.transfer;

                          print('🔄 양도 방식 변경 API 호출 시작');

                          final result = await transferService
                              .toggleTransferType(ticket.transferTicketId);

                          String? generatedCode;
                          if (result != null &&
                              result.containsKey('unique_code')) {
                            generatedCode = result['unique_code'];
                          }

                          setState(() {
                            isLoading = false;
                            isCompleted = true;
                            newGeneratedCode = generatedCode;
                          });

                          print('✅ 양도 방식 변경 완료');
                        } catch (e) {
                          print('❌ 양도 방식 변경 실패: $e');

                          setState(() {
                            isLoading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('양도 방식 변경에 실패했습니다'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 고유 번호 재생성 팝업
  static void showRegenerateCodeDialog(
    BuildContext context,
    MyTransferTicket ticket,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;
        String? newCode;
        bool isCompleted = false;

        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
                      Icon(Icons.refresh, color: AppColors.secondary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '고유 번호 재생성',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Spacer(),
                      if (!isLoading)
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                          ),
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

                  if (isLoading) ...[
                    _buildLoadingState('새로운 고유 번호를 생성하고 있습니다...'),
                  ] else if (isCompleted && newCode != null) ...[
                    _buildRegenerateCompletedState(context, ticket, newCode!),
                  ] else ...[
                    _buildRegenerateConfirmationState(
                      context,
                      ticket,
                      () async {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final transferProvider =
                              Provider.of<TransferProvider>(
                                context,
                                listen: false,
                              );

                          print('🔄 고유번호 재발급 API 호출 시작');

                          // 실제 API 호출
                          final uniqueCode = await transferProvider
                              .regenerateUniqueCode(ticket.transferTicketId);

                          if (uniqueCode != null) {
                            setState(() {
                              isLoading = false;
                              isCompleted = true;
                              newCode = uniqueCode.tempUniqueCode;
                            });
                            print(
                              '✅ 고유번호 재발급 완료: ${uniqueCode.tempUniqueCode}',
                            );
                          } else {
                            throw Exception('고유번호 생성 실패');
                          }
                        } catch (e) {
                          print('❌ 고유번호 재발급 실패: $e');

                          setState(() {
                            isLoading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('고유번호 재발급에 실패했습니다'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 로딩 상태 공통 위젯
  static Widget _buildLoadingState(String message) {
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
          message,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // 변경 확인 상태
  static Widget _buildChangeConfirmationState(
    BuildContext context,
    bool currentIsPublic,
    bool newIsPublic,
    VoidCallback onConfirm,
  ) {
    return Column(
      children: [
        // 변경 미리보기
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // 현재 방식
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      currentIsPublic ? Icons.public : Icons.lock,
                      color: currentIsPublic
                          ? AppColors.primary
                          : AppColors.secondary,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '현재: ${currentIsPublic ? '공개' : '비공개'} 양도',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Icon(Icons.arrow_forward, color: AppColors.textSecondary),

              // 변경될 방식
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      newIsPublic ? Icons.public : Icons.lock,
                      color: newIsPublic
                          ? AppColors.primary
                          : AppColors.secondary,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '변경: ${newIsPublic ? '공개' : '비공개'} 양도',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // 주의사항
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  !newIsPublic
                      ? '비공개로 변경 시 새로운 고유 번호가 생성됩니다'
                      : '공개로 변경 시 양도 마켓에 즉시 노출됩니다',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),

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
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('변경하기'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 변경 완료 상태
  static Widget _buildChangeCompletedState(
    BuildContext context,
    bool newIsPublic,
    String? newGeneratedCode,
    MyTransferTicket ticket,
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
          '양도 방식이 변경되었습니다!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        if (!newIsPublic && newGeneratedCode != null) ...[
          SizedBox(height: 20),
          Text(
            '새로 생성된 고유 번호',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          _buildUniqueCodeContainer(newGeneratedCode),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyUniqueCode(context, newGeneratedCode),
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
            onPressed: () {
              Navigator.pop(context);
              // 데이터 새로고침을 위해 상위에서 처리
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('양도 방식이 변경되었습니다'),
                  backgroundColor: AppColors.success,
                ),
              );
              // 데이터 새로고침
              final transferProvider = Provider.of<TransferProvider>(
                context,
                listen: false,
              );
              transferProvider.refreshData(userId: 1); // TODO: 실제 사용자 ID로 변경
            },
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

  // 재생성 확인 상태
  static Widget _buildRegenerateConfirmationState(
    BuildContext context,
    MyTransferTicket ticket,
    VoidCallback onConfirm,
  ) {
    return Column(
      children: [
        Text(
          '고유 번호를 재생성하시겠습니까?',
          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),

        SizedBox(height: 16),

        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                '현재 등록된 비공개 양도',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.lock, color: AppColors.secondary, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '고유번호가 재생성됩니다',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '기존 고유 번호는 즉시 무효화되며, 새로운 번호가 생성됩니다',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),

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
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('재생성'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 재생성 완료 상태
  static Widget _buildRegenerateCompletedState(
    BuildContext context,
    MyTransferTicket ticket,
    String newCode,
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
          '새로운 고유 번호가 생성되었습니다!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 20),

        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                '새로 생성된 고유 번호',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              SizedBox(height: 8),
              Text(
                newCode,
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
        ),

        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyUniqueCode(context, newCode),
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

        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('고유번호가 재생성되었습니다'),
                  backgroundColor: AppColors.success,
                ),
              );
              // 데이터 새로고침
              final transferProvider = Provider.of<TransferProvider>(
                context,
                listen: false,
              );
              transferProvider.refreshData(userId: 1); // TODO: 실제 사용자 ID로 변경
            },
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

  // 상태별 색상 반환
  static Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.secondary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.gray500;
      default:
        return AppColors.gray500;
    }
  }

  // 고유번호 복사 기능
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
