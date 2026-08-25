import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // CUSTOM ERROR NOTIFICATION WINDOW
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceDefault,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.primaryGreen, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  child: const Text("CLOSE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    String result = await AuthService().loginUser(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (result != "success") {
      _showErrorDialog("User doesn't exist with the following credentials. Register first and then login.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView( // PREVENTS KEYBOARD OVERFLOW
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.waves_rounded, color: AppColors.primaryGreen, size: 80),
              const SizedBox(height: 20),
              const Text("Veyra", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 40),

              _buildTextField(_emailController, "Email", Icons.email_outlined),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, "Password", Icons.lock_outline, isObscure: true),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog(),
                  child: const Text("Forgot Password?", style: TextStyle(color: AppColors.textMuted)),
                ),
              ),

              const SizedBox(height: 20),
              _isLoading
                ? const CircularProgressIndicator(color: AppColors.primaryGreen)
                : PrimaryButton(label: "Sign In", onPressed: _handleLogin),

              const SizedBox(height: 24),
              const Text("or", style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 24),

              // GOOGLE SIGN IN
              _buildSocialButton("Continue with Google", Icons.g_mobiledata),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                child: const Text("Don't have an account? Sign up", style: TextStyle(color: AppColors.primaryGreen)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () => AuthService().signInWithGoogle(),
      icon: Icon(icon, color: Colors.white, size: 30),
      label: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: AppColors.surfaceHigh),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDefault,
        title: const Text("Reset Password"),
        content: TextField(
          controller: resetEmailController,
          decoration: const InputDecoration(hintText: "Enter your registered email"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await AuthService().resetPassword(resetEmailController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset link sent to your email!")));
            },
            child: const Text("Send Link", style: TextStyle(color: AppColors.primaryGreen))
          ),
        ],
      ),
    );
  }
}
