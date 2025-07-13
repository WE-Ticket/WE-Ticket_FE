import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/api_provider.dart';
import '../../models/user_models.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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

                // 이름 입력
                _buildTextField(
                  controller: _nameController,
                  label: '이름',
                  hint: '실명을 입력하세요',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    if (!UserService.validateFullName(value)) {
                      return '이름은 2-20자로 입력해주세요';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // 아이디 입력
                _buildTextField(
                  controller: _idController,
                  label: '아이디',
                  hint: '4-20자의 영문, 숫자 조합',
                  icon: Icons.account_circle_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '아이디를 입력해주세요';
                    }
                    if (!UserService.validateLoginId(value)) {
                      return '아이디는 4-20자의 영문, 숫자만 사용 가능합니다';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // 휴대폰 번호 입력
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
                    if (value == null || value.isEmpty) {
                      return '휴대폰 번호를 입력해주세요';
                    }
                    if (!UserService.validatePhoneNumber(value)) {
                      return '올바른 휴대폰 번호를 입력해주세요 (01XXXXXXXXX)';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // 비밀번호 입력
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
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (!UserService.validatePassword(value)) {
                      return '비밀번호는 4자 이상 입력해주세요';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // 비밀번호 확인 입력
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
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 다시 입력해주세요';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24),

                // 약관 동의
                _buildTermsSection(),

                SizedBox(height: 32),

                // 회원가입 버튼
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

        // 서비스 이용약관
        InkWell(
          onTap: () {
            setState(() {
              _agreeTerms = !_agreeTerms;
            });
          },
          child: Row(
            children: [
              Checkbox(
                value: _agreeTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeTerms = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Text(
                  '서비스 이용약관 동의 (필수)',
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              TextButton(
                onPressed: () => _showTermsDialog('서비스 이용약관'),
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
        ),

        // 개인정보 처리방침
        InkWell(
          onTap: () {
            setState(() {
              _agreePrivacy = !_agreePrivacy;
            });
          },
          child: Row(
            children: [
              Checkbox(
                value: _agreePrivacy,
                onChanged: (value) {
                  setState(() {
                    _agreePrivacy = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Text(
                  '개인정보 처리방침 동의 (필수)',
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              TextButton(
                onPressed: () => _showTermsDialog('개인정보 처리방침'),
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
        ),

        SizedBox(height: 8),

        // 전체 동의
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray200),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                final allAgreed = _agreeTerms && _agreePrivacy;
                _agreeTerms = !allAgreed;
                _agreePrivacy = !allAgreed;
              });
            },
            child: Row(
              children: [
                Checkbox(
                  value: _agreeTerms && _agreePrivacy,
                  onChanged: (value) {
                    setState(() {
                      _agreeTerms = value ?? false;
                      _agreePrivacy = value ?? false;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Text(
                    '전체 약관에 동의합니다',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return Consumer<ApiProvider>(
      builder: (context, apiProvider, child) {
        final isLoading = _isLoading || apiProvider.isLoading;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: AppColors.primary.withOpacity(0.3),
            ),
            child: isLoading
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
      },
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
본 약관은 WE-Ticket(이하 "회사")에서 제공하는 NFT 기반 티켓팅 서비스의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "서비스"란 회사가 제공하는 NFT 기반 공연 티켓 예매, 관리, 양도 등의 서비스를 말합니다.
2. "이용자"란 본 약관에 따라 회사가 제공하는 서비스를 받는 회원 및 비회원을 말합니다.
3. "NFT 티켓"이란 블록체인 기술을 활용하여 발행되는 디지털 티켓을 말합니다.

제3조 (약관의 게시와 개정)
1. 회사는 본 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 초기 화면에 게시합니다.
2. 회사는 필요한 경우 관련 법령을 위배하지 않는 범위에서 본 약관을 개정할 수 있습니다.

(이하 생략...)''';
    } else {
      return '''개인정보 처리방침

WE-Ticket(이하 "회사")은 개인정보 보호법에 따라 이용자의 개인정보 보호 및 권익을 보호하고자 다음과 같은 처리방침을 두고 있습니다.

1. 개인정보의 처리목적
회사는 다음의 목적을 위하여 개인정보를 처리하고 있으며, 다음의 목적 이외의 용도로는 이용하지 않습니다.
- 회원 가입 및 관리
- 서비스 제공에 관한 계약 이행 및 서비스 제공에 따른 요금정산
- NFT 티켓 발행 및 관리

2. 개인정보의 처리 및 보유기간
회사는 정보주체로부터 개인정보를 수집할 때 동의받은 개인정보 보유·이용기간 또는 법령에 따른 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.

3. 개인정보의 제3자 제공
회사는 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. 다만, 아래의 경우에는 예외로 합니다.
- 이용자들이 사전에 동의한 경우
- 법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우

(이하 생략...)''';
    }
  }

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

    // 추가 유효성 검사
    final validationError = UserService.validateSignupData(
      fullName: _nameController.text.trim(),
      loginId: _idController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
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
      await _handleApiSignup();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleApiSignup() async {
    try {
      final apiProvider = context.read<ApiProvider>();

      // Agreement 객체 생성
      final agreements = <Agreement>[
        Agreement(
          termType: 'SERVICE_TERMS',
          agreed: _agreeTerms,
          agreedAt: DateTime.now().toIso8601String().split('T')[0],
        ),
        Agreement(
          termType: 'PRIVACY_POLICY',
          agreed: _agreePrivacy,
          agreedAt: DateTime.now().toIso8601String().split('T')[0],
        ),
      ];

      // SignupRequest 생성
      final signupRequest = SignupRequest(
        fullName: _nameController.text.trim(),
        loginId: _idController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        loginPassword: _passwordController.text,
        agreements: agreements,
      );

      print('📝 API 회원가입 시도: ${signupRequest.loginId}');
      final response = await apiProvider.apiService.user.signup(signupRequest);

      if (response.isSuccess) {
        // 회원가입 성공
        print('✅ API 회원가입 성공: ${response.message}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입이 완료되었습니다! 로그인해주세요.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

        // 로그인 화면으로 돌아가기
        Navigator.pop(context);
      } else {
        // 회원가입 실패
        print('❌ API 회원가입 실패: ${response.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입 실패: ${response.message}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ API 회원가입 오류: $e');
      String errorMessage = '회원가입 중 오류가 발생했습니다.';

      // 에러 타입에 따른 메시지 설정
      if (e.toString().contains('연결')) {
        errorMessage = '서버에 연결할 수 없습니다. 네트워크를 확인해주세요.';
      } else if (e.toString().contains('duplicate') ||
          e.toString().contains('중복')) {
        errorMessage = '이미 사용 중인 아이디이거나 휴대폰 번호입니다.';
      } else if (e.toString().contains('400')) {
        errorMessage = '입력 정보가 올바르지 않습니다. 다시 확인해주세요.';
      } else if (e.toString().contains('500')) {
        errorMessage = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
