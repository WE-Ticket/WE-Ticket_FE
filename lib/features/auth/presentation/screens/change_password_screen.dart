import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/presentation/widgets/app_snackbar.dart';
import '../../../../shared/presentation/providers/api_provider.dart';
import '../../data/auth_service.dart';

enum PasswordChangeStep { phoneVerify, codeVerify, setNewPassword, completed }

class ChangePasswordScreen extends StatefulWidget {
  final String currentUserId;
  
  const ChangePasswordScreen({
    super.key, 
    required this.currentUserId,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PasswordChangeStep _currentStep = PasswordChangeStep.phoneVerify;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiProvider = context.read<ApiProvider>();
      final authService = AuthService(apiProvider.dioClient);
      final result = await authService.findPassword(
        phoneNumber: _phoneController.text.trim(),
        loginId: widget.currentUserId,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() => _currentStep = PasswordChangeStep.codeVerify);
        
        // 테스트 모드: 응답에서 인증코드 추출하여 다이얼로그로 표시
        if (result.data != null && result.data!.verificationCode != null) {
          _showTestModeCodeDialog(context, result.data!.verificationCode!);
        } else {
          AppSnackBar.showSuccess(context, '인증코드가 발송되었습니다.');
        }
      } else {
        AppSnackBar.showError(context, result.errorMessage ?? '인증코드 발송에 실패했습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, '오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiProvider = context.read<ApiProvider>();
      final authService = AuthService(apiProvider.dioClient);
      final result = await authService.verifyPassword(
        phoneNumber: _phoneController.text.trim(),
        loginId: widget.currentUserId,
        code: _codeController.text.trim(),
      );

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() => _currentStep = PasswordChangeStep.setNewPassword);
        AppSnackBar.showSuccess(context, '인증이 완료되었습니다.');
      } else {
        AppSnackBar.showError(context, result.errorMessage ?? '인증에 실패했습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, '오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiProvider = context.read<ApiProvider>();
      final authService = AuthService(apiProvider.dioClient);
      final result = await authService.resetPassword(
        phoneNumber: _phoneController.text.trim(),
        loginId: widget.currentUserId,
        newPassword: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() => _currentStep = PasswordChangeStep.completed);
        AppSnackBar.showSuccess(context, '비밀번호가 성공적으로 변경되었습니다.');
      } else {
        AppSnackBar.showError(context, result.errorMessage ?? '비밀번호 변경에 실패했습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, '오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          '비밀번호 변경',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressIndicator(),
                SizedBox(height: 24),
                _buildInstructions(),
                SizedBox(height: 24),
                
                if (_currentStep == PasswordChangeStep.phoneVerify)
                  _buildPhoneVerifyStep()
                else if (_currentStep == PasswordChangeStep.codeVerify)
                  _buildCodeVerifyStep()
                else if (_currentStep == PasswordChangeStep.setNewPassword)
                  _buildPasswordResetStep()
                else
                  _buildCompletedStep(),
                
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStepIndicator(1, '정보 입력', _currentStep.index >= 0),
        Expanded(child: Divider()),
        _buildStepIndicator(2, '인증', _currentStep.index >= 1),
        Expanded(child: Divider()),
        _buildStepIndicator(3, '비밀번호 변경', _currentStep.index >= 2),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.gray300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? AppColors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    String text;
    switch (_currentStep) {
      case PasswordChangeStep.phoneVerify:
        text = '계정과 연결된 전화번호를 입력해주세요. (전화번호는 하이픈 없이 입력)';
        break;
      case PasswordChangeStep.codeVerify:
        text = '전화번호로 발송된 인증코드를 입력해주세요.';
        break;
      case PasswordChangeStep.setNewPassword:
        text = '새로 사용할 비밀번호를 입력해주세요.';
        break;
      case PasswordChangeStep.completed:
        text = '비밀번호 변경이 완료되었습니다.';
        break;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneVerifyStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _phoneController,
          label: '전화번호',
          hintText: '01012345678',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '전화번호를 입력해주세요';
            }
            if (!RegExp(r'^01[0-9]\d{7,8}$').hasMatch(value.trim())) {
              return '올바른 전화번호 형식으로 입력해주세요 (01012345678)';
            }
            return null;
          },
        ),
        SizedBox(height: 24),
        _buildActionButton('인증코드 발송', _sendCode),
      ],
    );
  }

  Widget _buildCodeVerifyStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _codeController,
          label: '인증코드',
          hintText: '6자리 인증코드를 입력하세요',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '인증코드를 입력해주세요';
            }
            if (value.trim().length != 6) {
              return '6자리 인증코드를 입력해주세요';
            }
            return null;
          },
        ),
        SizedBox(height: 24),
        _buildActionButton('인증하기', _verifyCode),
      ],
    );
  }

  Widget _buildPasswordResetStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _passwordController,
          label: '새 비밀번호',
          hintText: '새로운 비밀번호를 입력하세요',
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '비밀번호를 입력해주세요';
            }
            if (value.length < 8) {
              return '비밀번호는 8자 이상이어야 합니다';
            }
            if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z\d]{8,}$')
                .hasMatch(value)) {
              return '영문, 숫자 조합 8자리 이상이어야 합니다';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordController,
          label: '비밀번호 확인',
          hintText: '비밀번호를 다시 입력하세요',
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '비밀번호 확인을 입력해주세요';
            }
            if (value != _passwordController.text) {
              return '비밀번호가 일치하지 않습니다';
            }
            return null;
          },
        ),
        SizedBox(height: 24),
        _buildActionButton('비밀번호 변경', _resetPassword),
      ],
    );
  }

  Widget _buildCompletedStep() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            '비밀번호 변경 완료!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '새로운 비밀번호로 로그인해주세요.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '돌아가기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: AppColors.textSecondary),
            suffixIcon: suffixIcon,
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: AppColors.white)
            : Text(
                text,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  void _showTestModeCodeDialog(BuildContext context, String verificationCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bug_report, color: AppColors.warning, size: 24),
            SizedBox(width: 8),
            Text(
              '테스트 모드',
              style: TextStyle(color: AppColors.warning),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '실제 문자는 발송되지 않습니다.\n테스트용 인증코드를 확인하세요.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '인증코드',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  SelectableText(
                    verificationCode,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.info),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '코드를 선택하여 복사할 수 있습니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: verificationCode));
              if (!context.mounted) return;
              Navigator.pop(context);
              AppSnackBar.showSuccess(context, '인증코드가 클립보드에 복사되었습니다.');
            },
            child: Text('복사하고 닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              _codeController.text = verificationCode;
              Navigator.pop(context);
              AppSnackBar.showSuccess(context, '인증코드가 자동으로 입력되었습니다.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: Text('자동 입력'),
          ),
        ],
      ),
    );
  }
}