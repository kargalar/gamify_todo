import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Service/auth_service.dart';
import 'package:next_level/General/app_colors.dart';

class ModernRegisterPage extends StatefulWidget {
  const ModernRegisterPage({super.key});

  @override
  State<ModernRegisterPage> createState() => _ModernRegisterPageState();
}

class _ModernRegisterPageState extends State<ModernRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      Helper().getMessage(message: "Şifreler eşleşmiyor");
      return;
    }

    debugPrint('📝 Starting registration process...');
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await AuthService().registerWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );

      debugPrint('📝 Registration result: ${user != null ? "SUCCESS" : "FAILED"}');

      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        debugPrint('📝 User registered successfully, waiting for auth state change...');
        // AuthWrapper will handle navigation automatically
      } else {
        debugPrint('📝 Registration failed');
      }
    } catch (e) {
      debugPrint('📝 Registration error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.main.withAlpha(25),
              AppColors.main.withAlpha(13),
              AppColors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.deepContrast,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.transparantBlack,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.main,
                          size: 16,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),

                      // Header Section
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.deepContrast,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.main.withAlpha(51),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo/logo.png',
                          height: 60.h,
                          width: 60.w,
                        ),
                      ),

                      SizedBox(height: 24.h),

                      Text(
                        'Hesap Oluştur',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.main,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        'Yeni bir hesap oluşturarak\ngörev yönetimi deneyiminizi başlatın',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.grey,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 40.h),

                      // Form Section
                      Container(
                        padding: EdgeInsets.all(32.w),
                        decoration: BoxDecoration(
                          color: AppColors.deepContrast,
                          borderRadius: BorderRadius.circular(32.r),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.transparantBlack,
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Username Field
                              _buildTextField(
                                controller: _usernameController,
                                labelText: 'Kullanıcı Adı',
                                hintText: 'Kullanıcı adınızı girin',
                                icon: Icons.person_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kullanıcı adı gerekli';
                                  }
                                  if (value.length < 3) {
                                    return 'Kullanıcı adı en az 3 karakter olmalı';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 20.h),

                              // Email Field
                              _buildTextField(
                                controller: _emailController,
                                labelText: 'E-posta',
                                hintText: 'ornek@email.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                isEmailField: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'E-posta gerekli';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Geçerli bir e-posta adresi girin';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 20.h),

                              // Password Field
                              _buildTextField(
                                controller: _passwordController,
                                labelText: 'Şifre',
                                hintText: '••••••••',
                                icon: Icons.lock_outlined,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: AppColors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Şifre gerekli';
                                  }
                                  if (value.length < 6) {
                                    return 'Şifre en az 6 karakter olmalı';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 20.h),

                              // Confirm Password Field
                              _buildTextField(
                                controller: _confirmPasswordController,
                                labelText: 'Şifre Tekrar',
                                hintText: '••••••••',
                                icon: Icons.lock_outlined,
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: AppColors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Şifre tekrarı gerekli';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Şifreler eşleşmiyor';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 32.h),

                              // Register Button
                              _buildGradientButton(
                                onPressed: _isLoading ? null : _signUp,
                                text: 'Hesap Oluştur',
                                isLoading: _isLoading,
                              ),

                              SizedBox(height: 24.h),

                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Zaten hesabınız var mı? ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      'Giriş Yap',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.main,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    bool isEmailField = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.grey.withAlpha(51),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autocorrect: false,
        enableSuggestions: isEmailField,
        autofillHints: isEmailField
            ? [AutofillHints.email]
            : obscureText
                ? [AutofillHints.password, AutofillHints.newPassword]
                : [AutofillHints.username],
        textInputAction: TextInputAction.next,
        style: GoogleFonts.poppins(fontSize: 14),
        onChanged: (value) {
          // Otomatik trim işlemi (password hariç)
          if (!obscureText && value != value.trim()) {
            controller.value = controller.value.copyWith(
              text: value.trim(),
              selection: TextSelection.collapsed(offset: value.trim().length),
            );
          }
        },
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Container(
            margin: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.main.withAlpha(25),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: AppColors.main,
              size: 18,
            ),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 16.h,
          ),
          labelStyle: GoogleFonts.poppins(
            color: AppColors.grey,
            fontSize: 12,
          ),
          hintStyle: GoogleFonts.poppins(
            color: AppColors.dirtyWhite,
            fontSize: 12,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.main,
            AppColors.lightMain,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.main.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24.h,
                width: 24.w,
                child: CircularProgressIndicator(
                  color: AppColors.deepContrast,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}
