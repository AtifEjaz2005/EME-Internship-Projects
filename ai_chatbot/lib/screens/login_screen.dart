import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ai_chatbot/backend/login/login_logic.dart';
import '../themes/app_theme.dart';
import 'package:ai_chatbot/widgets/login/login_form_widget.dart';
import 'package:ai_chatbot/widgets/login/forget_password_form.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginLogic logic = LoginLogic();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(color: Color(0xFF161717)),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(25),
                constraints: const BoxConstraints(minHeight: 500),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    const Text("Login", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 35),

                    LoginField(controller: logic.emailController, hint: "Email", icon: Icons.email),
                    LoginField(controller: logic.passController, hint: "Password", icon: Icons.lock, isPass: true),

                    const SizedBox(height: 35),

                    logic.isLoading
                        ? const CircularProgressIndicator(color: AppTheme.limeGreen)
                        : SizedBox(
                            width: double.infinity, height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkBackground),
                              onPressed: () => logic.performLogin(
                                context: context,
                                updateUI: () => setState(() {}),
                              ),
                              child: const Text("LOGIN", style: TextStyle(color: AppTheme.limeGreen, fontWeight: FontWeight.bold)),
                            ),
                          ),
                    const SizedBox(height: 25),

                    _buildFooterLinks(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(text: "Doesn't have an account? ", style: TextStyle(color: Colors.white70)),
              TextSpan(
                text: "Register here",
                style: const TextStyle(color: AppTheme.limeGreen, fontWeight: FontWeight.bold),
                recognizer: TapGestureRecognizer()..onTap = () {
                  logic.clearFields();
                  Navigator.of(context).push(_createRoute());
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () => showDialog(context: context, builder: (c) => const ForgotPasswordDialog()),
          child: const Text("Forgot Password?", style: TextStyle(color: AppTheme.limeGreen)),
        ),
      ],
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (c, a, sa) => const RegisterScreen(),
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (c, a, sa, child) {
        var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.fastLinearToSlowEaseIn));
        return FadeTransition(opacity: a, child: SlideTransition(position: a.drive(tween), child: child));
      },
    );
  }
}
