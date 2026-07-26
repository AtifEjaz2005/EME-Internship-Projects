import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../database/auth_services.dart';

class ForgotPasswordDialog extends StatelessWidget {
  const ForgotPasswordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController resetEmailController = TextEditingController();

    return AlertDialog(
      backgroundColor: AppTheme.darkBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: const Text("Reset Password", textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter your email for a reset link.", textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: resetEmailController,
              style: const TextStyle(color: AppTheme.limeGreen),
              decoration: const InputDecoration(
                hintText: "Email", hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.email, color: AppTheme.limeGreen, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.limeGreen),
          onPressed: () async {
            if (resetEmailController.text.isEmpty) return;
            await AuthService.instance.resetPassword(resetEmailController.text);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset link sent!")));
          },
          child: const Text("Send", style: TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
