import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:we_ticket/features/auth/data/auth_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/app_colors.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // 폼 컨트롤러
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _isLoading = false;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(DioClient());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
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
          '회원가입',
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
                SizedBox(height: 20),
                _buildHeaderSection(),
                SizedBox(height: 32),
                _buildTextField(
                  controller: _nameController,
                  label: '이름',
                  hint: '실명을 입력하세요',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    if (value.trim().length < 2 || value.trim().length > 20) {
                      return '이름은 2-20자로 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _idController,
                  label: '아이디',
                  hint: '4-20자의 영문, 숫자 조합',
                  icon: Icons.account_circle_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '아이디를 입력해주세요';
                    }
                    if (value.length < 4 || value.length > 20) {
                      return '아이디는 4-20자로 입력해주세요';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                      return '아이디는 영문, 숫자만 사용 가능합니다';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: '휴대폰 번호',
                  hint: '01012345678 (하이픈 없이)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '휴대폰 번호를 입력해주세요';
                    }
                    if (!RegExp(r'^01[0-9]{8,9}$').hasMatch(value)) {
                      return '올바른 휴대폰 번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildPasswordField(
                  controller: _passwordController,
                  label: '비밀번호',
                  hint: '4자 이상 입력하세요',
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 4) {
                      return '비밀번호는 4자 이상 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: '비밀번호 확인',
                  hint: '비밀번호를 다시 입력하세요',
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '비밀번호를 다시 입력해주세요';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                _buildTermsSection(),
                SizedBox(height: 32),
                _buildSignupButton(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '회원 정보를 입력해주세요',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'WE-Ticket에서 안전한 NFT 티켓팅을 경험해보세요',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '약관 동의',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        _buildTermCheckbox(
          value: _agreeTerms,
          text: '서비스 이용약관 동의 (필수)',
          onChanged: (value) => setState(() => _agreeTerms = value ?? false),
          onViewTerms: () => _showTermsDialog('서비스 이용약관'),
        ),
        _buildTermCheckbox(
          value: _agreePrivacy,
          text: '개인정보 처리방침 동의 (필수)',
          onChanged: (value) => setState(() => _agreePrivacy = value ?? false),
          onViewTerms: () => _showTermsDialog('개인정보 처리방침'),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray200),
          ),
          child: _buildTermCheckbox(
            value: _agreeTerms && _agreePrivacy,
            text: '전체 약관에 동의합니다',
            fontWeight: FontWeight.w600,
            onChanged: (value) {
              setState(() {
                _agreeTerms = value ?? false;
                _agreePrivacy = value ?? false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTermCheckbox({
    required bool value,
    required String text,
    required ValueChanged<bool?> onChanged,
    VoidCallback? onViewTerms,
    FontWeight? fontWeight,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: fontWeight,
              ),
            ),
          ),
          if (onViewTerms != null)
            TextButton(
              onPressed: onViewTerms,
              child: Text(
                '보기',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🔥 간단한 로딩 상태가 포함된 회원가입 버튼
  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                '회원가입',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  void _showTermsDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(
              _getTermsContent(title),
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  String _getTermsContent(String title) {
    if (title == '서비스 이용약관') {
      return '''WE-Ticket 서비스 이용약관

제1조 (목적)
본 약관은 WE-Ticket에서 제공하는 NFT 기반 티켓팅 서비스의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "서비스"란 회사가 제공하는 NFT 기반 공연 티켓 예매, 관리, 양도 등의 서비스를 말합니다.
2. "이용자"란 본 약관에 따라 회사가 제공하는 서비스를 받는 회원을 말합니다.
3. "NFT 티켓"이란 블록체인 기술을 활용하여 발행되는 디지털 티켓을 말합니다.

(이하 생략...)''';
    } else {
      return '''개인정보 처리방침

WE-Ticket은 개인정보 보호법에 따라 이용자의 개인정보 보호 및 권익을 보호하고자 다음과 같은 처리방침을 두고 있습니다.

1. 개인정보의 처리목적
- 회원 가입 및 관리
- 서비스 제공에 관한 계약 이행
- NFT 티켓 발행 및 관리

2. 개인정보의 처리 및 보유기간
회사는 법령에 따른 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.

(이하 생략...)''';
    }
  }

  // 🔥 AuthService를 직접 사용하는 회원가입 처리
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeTerms || !_agreePrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('필수 약관에 모두 동의해주세요'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 🔥 AuthService 직접 호출 - 간단!
      final result = await _authService.signup(
        fullName: _nameController.text.trim(),
        loginId: _idController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        agreeTerms: _agreeTerms,
        agreePrivacy: _agreePrivacy,
      );

      if (result.isSuccess) {
        // 회원가입 성공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입이 완료되었습니다! 로그인해주세요.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.pop(context);
      } else {
        // 회원가입 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? '회원가입에 실패했습니다'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // 예외 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원가입 중 오류가 발생했습니다'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
