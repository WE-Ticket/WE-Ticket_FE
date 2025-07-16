import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/auth/data/services/user_service.dart';
import '../providers/auth_provider.dart';
import '../../../shared/providers/api_provider.dart';
import '../../data/models/user_models.dart';
import '../../../../core/constants/app_colors.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
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
          '로그인',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // 더이상 모드 전환 버튼 불필요
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),

              _buildWelcomeSection(),

              SizedBox(height: 40),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildIdField(),
                    SizedBox(height: 16),
                    _buildPasswordField(),
                    SizedBox(height: 12),
                    _buildRememberMeAndFindPassword(),
                    SizedBox(height: 24),
                    _buildLoginButton(),
                  ],
                ),
              ),

              SizedBox(height: 20),

              _buildDivider(),

              SizedBox(height: 20),

              //소셜 로그인
              _buildSocialLogin(),

              SizedBox(height: 24),

              _buildSignupLink(),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number, size: 45, color: AppColors.primary),
            SizedBox(width: 10),
            Text(
              'WE-Ticket',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        SizedBox(height: 8),

        Text(
          '암표 근절을 위한 NFT 티켓팅 플랫폼',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIdField() {
    return TextFormField(
      controller: _idController,
      decoration: InputDecoration(
        labelText: '아이디',
        hintText: '아이디를 입력하세요',
        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '아이디를 입력해주세요';
        }
        if (!UserService.validateLoginId(value)) {
          return '아이디는 4-20자의 영문, 숫자만 사용 가능합니다';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: '비밀번호',
        hintText: '비밀번호를 입력하세요',
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '비밀번호를 입력해주세요';
        }
        if (!UserService.validatePassword(value)) {
          return '비밀번호는 4자 이상 입력해주세요';
        }
        return null;
      },
    );
  }

  Widget _buildRememberMeAndFindPassword() {
    return Row(
      children: [
        // 로그인 상태 유지
        GestureDetector(
          onTap: () {
            setState(() {
              _rememberMe = !_rememberMe;
            });
          },
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _rememberMe ? AppColors.primary : AppColors.surface,
                  border: Border.all(
                    color: _rememberMe ? AppColors.primary : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _rememberMe
                    ? Icon(Icons.check, size: 14, color: AppColors.white)
                    : null,
              ),
              SizedBox(width: 8),
              Text(
                '로그인 상태 유지',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        Spacer(),

        // 아이디/비밀번호 찾기
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('아이디/비밀번호 찾기 기능은 추후 구현 예정입니다.')),
            );
          },
          child: Text(
            '아이디/비밀번호 찾기',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer2<AuthProvider, ApiProvider>(
      builder: (context, authProvider, apiProvider, child) {
        final isLoading = _isLoading || apiProvider.isLoading;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
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
                    '로그인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '또는',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Text(
          '소셜 계정으로 간편 로그인',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),

        SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Google 로그인
            _buildSocialButton(
              'Google',
              Colors.white,
              AppColors.textPrimary,
              () => _handleSocialLogin('Google'),
            ),

            // Kakao 로그인
            _buildSocialButton(
              'Kakao',
              Color(0xFFFFE812),
              AppColors.textPrimary,
              () => _handleSocialLogin('Kakao'),
            ),

            // Apple 로그인
            _buildSocialButton(
              'Apple',
              AppColors.black,
              AppColors.white,
              () => _handleSocialLogin('Apple'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String name,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '아직 계정이 없으신가요? ',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignupScreen()),
            );
          },
          child: Text(
            '회원가입',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loginId = _idController.text.trim();
      final password = _passwordController.text;

      // API 로그인만 사용
      await _handleApiLogin(loginId, password);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleApiLogin(String loginId, String password) async {
    try {
      final apiProvider = context.read<ApiProvider>();
      final loginRequest = LoginRequest(
        loginId: loginId,
        loginPassword: password,
      );

      print('🔐 API 로그인 시도: $loginId');
      final response = await apiProvider.apiService.user.login(loginRequest);

      if (response.isSuccess) {
        // API 로그인 성공
        print('✅ API 로그인 성공: ${response.message}');

        // 사용자 정보 저장 (UserService)
        await apiProvider.apiService.user.saveUserInfo(response);

        // AuthProvider 상태 업데이트 (중요!)
        final authProvider = context.read<AuthProvider>();
        await authProvider.setLoggedIn(
          userId: response.userId.toString(),
          userName: response.message, // 또는 실제 사용자 이름이 있다면 사용
          // token: response.token, // 토큰이 있다면 추가
        );

        // 로그인 성공 처리
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 성공!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // API 로그인 실패
        print('❌ API 로그인 실패: ${response.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: ${response.message}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ API 로그인 오류: $e');
      String errorMessage = '로그인 중 오류가 발생했습니다.';

      // 에러 타입에 따른 메시지 설정
      if (e.toString().contains('연결')) {
        errorMessage = '서버에 연결할 수 없습니다. 네트워크를 확인해주세요.';
      } else if (e.toString().contains('401') || e.toString().contains('로그인')) {
        errorMessage = '아이디 또는 비밀번호가 올바르지 않습니다.';
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

  void _handleSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider 로그인은 추후 구현 예정입니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
