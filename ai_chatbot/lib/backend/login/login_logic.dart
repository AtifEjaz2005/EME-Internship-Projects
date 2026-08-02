import 'package:flutter/material.dart';
import '../../database/auth_services.dart';
import 'package:ai_chatbot/screens/onboarding.dart';
import 'package:ai_chatbot/screens/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class LoginLogic {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  bool isLoading = false;
  final AuthService auth = AuthService.instance;

  // Clear text boxes
  void clearFields() {
    emailController.clear();
    passController.clear();
  }

  // Handle the Login button click
  Future<void> performLogin({
    required BuildContext context,
    required Function updateUI,
  }) async {
    String email = emailController.text.trim();
    String password = passController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    isLoading = true;
    updateUI();

    // 1. Log in via Firebase
    var user = await auth.login(email, password);

    if (user != null) {
      // 2. Look at their profile in the database
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // 3. Check if they finished onboarding
      bool hasDoneTour = userDoc.get('hasCompletedOnboarding') ?? false;

      if (context.mounted) {
        isLoading = false;
        updateUI();

        // 4. Send to Onboarding if new, or Chat if old user
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (c) =>
                hasDoneTour ? const ChatScreen() : const OnboardingMain(),
          ),
        );
      }
    } else {
      isLoading = false;
      updateUI();
    }
  }
}
