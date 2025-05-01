import 'package:flutter/material.dart';
import 'package:gamify_todo/General/accessible.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Login/login_page.dart';
import 'package:gamify_todo/Page/navbar_page_manager.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:gamify_todo/Provider/navbar_provider.dart';
import 'package:get/route_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RegisterScreen(),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Hesap Oluştur', style: TextStyle(color: AppColors.white, fontSize: 24)),
                const SizedBox(height: 20),
                _buildTextField('E-Posta', controller: _emailController, validator: _emailValidator),
                const SizedBox(height: 16),
                _buildTextField('Şifre', controller: _passwordController, obscureText: true, validator: _passwordValidator),
                const SizedBox(height: 20),
                _buildRegisterButton(),
                const SizedBox(height: 5),
                _buildFooterLinks(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {bool obscureText = false, TextEditingController? controller, String? Function(String?)? validator}) {
    return TextFormField(
      obscureText: obscureText,
      controller: controller,
      keyboardType: !obscureText ? TextInputType.emailAddress : null,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      style: const TextStyle(color: AppColors.white),
      validator: validator,
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            loginUser = await ServerManager().register(
              email: _emailController.text,
              password: _passwordController.text,
            );

            if (loginUser != null) {
              // SharedPreferences
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString('email', _emailController.text);
              prefs.setString('password', _passwordController.text);

              NavbarProvider().currentIndex = 1;

              await Get.offUntil(
                GetPageRoute(
                  page: () => const NavbarPageManager(),
                  routeName: "/",
                ),
                (route) => false,
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Hesap Oluştur', style: TextStyle(color: AppColors.white)),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () async {
            Get.offUntil(
              GetPageRoute(
                page: () => const LoginPage(),
              ),
              (route) => false,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            color: AppColors.transparent,
            child: const Text(
              'Giriş yap',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen e-posta adresinizi girin';
    }
    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen şifrenizi girin';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }
    return null;
  }
}
