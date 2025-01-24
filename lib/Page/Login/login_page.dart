import 'package:flutter/material.dart';
import 'package:gamify_todo/General/accessible.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Login/register_page.dart';
import 'package:gamify_todo/Page/navbar_page_manager.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:gamify_todo/Provider/navbar_provider.dart';
import 'package:get/route_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    Widget buildLoginButton() {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            loginUser = await ServerManager().login(
              email: emailController.text,
              password: passwordController.text,
            );

            if (loginUser != null) {
              // SharedPreferences
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString('email', emailController.text);
              prefs.setString('password', passwordController.text);

              NavbarProvider().currentIndex = 1;

              await Get.offUntil(
                GetPageRoute(
                  page: () => const NavbarPageManager(),
                  routeName: "/",
                ),
                (route) => false,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Giriş Yap', style: TextStyle(color: AppColors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Giriş', style: TextStyle(color: AppColors.white, fontSize: 24)),
              const SizedBox(height: 20),
              _buildTextField('E-Posta', controller: emailController),
              const SizedBox(height: 16),
              _buildTextField('Şifre', obscureText: true, controller: passwordController),
              const SizedBox(height: 20),
              buildLoginButton(),
              const SizedBox(height: 16),
              _buildFooterLinks(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {bool obscureText = false, required TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: !obscureText ? TextInputType.emailAddress : null,
      autofillHints: !obscureText ? const [AutofillHints.email] : null,
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
                page: () => const RegisterPage(),
              ),
              (route) => false,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            color: AppColors.transparent,
            child: const Text(
              'Hesap oluştur',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }
}
