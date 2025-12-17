import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/presentation/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/mypage_provider.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({Key? key}) : super(key: key);

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentsController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final mypageProvider = context.read<MyPageProvider>();

    if (authProvider.currentUserId == null) {
      AppSnackBar.showError(context, '로그인이 필요합니다.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await mypageProvider.submitInquiry(
        userId: authProvider.currentUserId!,
        inquiryTitle: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        inquiryContents: _contentsController.text.trim(),
      );

      if (success) {
        AppSnackBar.showSuccess(context, '문의가 성공적으로 등록되었습니다.');
        Navigator.pop(context);
      } else {
        final errorMessage = mypageProvider.errorMessage ?? '문의 등록에 실패했습니다.';
        AppSnackBar.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          '1:1 문의',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInstructions(),

                        SizedBox(height: 24),

                        _buildTitleField(),

                        SizedBox(height: 20),

                        _buildContentsField(),

                        SizedBox(height: 20),

                        _buildSubmitButton(),

                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom > 0
                              ? 20
                              : 40,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                '문의 안내',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• 문의 제목은 최대 200자까지 입력 가능합니다.\n'
            '• 문의 내용을 자세히 작성해 주시면 빠른 답변에 도움이 됩니다.\n'
            '• 등록된 문의는 고객센터에서 확인 후 답변드립니다.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '문의 제목',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '(선택)',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),

        SizedBox(height: 8),

        TextFormField(
          controller: _titleController,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: '문의 제목을 입력해주세요 (선택사항)',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            counterText: '',
          ),
        ),

        SizedBox(height: 4),

        Text(
          '${_titleController.text.length}/200',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildContentsField() {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '문의 내용',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 4),
              Text('*', style: TextStyle(fontSize: 16, color: AppColors.error)),
            ],
          ),

          SizedBox(height: 8),

          Container(
            height: 200,
            child: TextFormField(
              controller: _contentsController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '문의 내용을 입력해주세요.';
                }
                if (value.trim().length < 10) {
                  return '문의 내용을 10자 이상 입력해주세요.';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText:
                    '궁금한 점이나 문의사항을 자세히 작성해주세요.\n\n'
                    '• 티켓 구매 관련 문의\n'
                    '• 본인인증 관련 문의\n'
                    '• 서비스 이용 중 오류\n'
                    '• 기타 문의사항',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.gray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.error, width: 2),
                ),
                contentPadding: EdgeInsets.all(16),
                alignLabelWithHint: true,
              ),
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Column(
          children: [
            if (user != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '문의자: ${user.userName} (@${user.loginId})',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            if (_isLoading)
              Container(
                height: 56,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitInquiry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '문의 등록',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
