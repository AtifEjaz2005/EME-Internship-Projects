import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ai_chatbot/backend/register/register_logic.dart';
import '../themes/app_theme.dart';
import 'package:ai_chatbot/widgets/register/register_form_fields.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final RegisterLogic logic = RegisterLogic();

  @override
  void dispose() {
    logic.dispose(); // Clean up memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: AppTheme.gradientBg,
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text("Create Account", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 25),

                    // Using the Template for all 5 boxes
                    RegisterField(controller: logic.fName, hint: "First Name", icon: Icons.person),
                    RegisterField(controller: logic.lName, hint: "Last Name", icon: Icons.person_outline),
                    RegisterField(controller: logic.phone, hint: "Phone Number", icon: Icons.phone),
                    RegisterField(controller: logic.email, hint: "Email", icon: Icons.email),
                    RegisterField(controller: logic.pass, hint: "Password", icon: Icons.lock, isPass: true),

                    const SizedBox(height: 25),

                    // Show Spinner OR Button
                    logic.isLoading
                        ? const CircularProgressIndicator(color: AppTheme.limeGreen)
                        : SizedBox(
                            width: double.infinity, height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkBackground),
                              onPressed: () => logic.performRegister(
                                context: context,
                                updateUI: () => setState(() {}),
                                goBack: () => Navigator.pop(context),
                              ),
                              child: const Text("REGISTER", style: TextStyle(color: AppTheme.limeGreen, fontWeight: FontWeight.bold)),
                            ),
                          ),
                    const SizedBox(height: 20),

                    _buildFooterLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(text: "Already have an account? ", style: TextStyle(color: AppTheme.limeGreen)),
          TextSpan(
            text: "Login here",
            style: const TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()..onTap = () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
