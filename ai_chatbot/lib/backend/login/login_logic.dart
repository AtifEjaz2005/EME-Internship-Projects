import 'package:flutter/material.dart';
import '../../database/auth_services.dart';

class LoginLogic {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  bool isLoading = false;
  final AuthService auth = AuthService.instance;

  // Clear text boxes
  void clearFields() {
    nameController.clear();
    emailController.clear();
    passController.clear();
  }

  // Handle the Login button click
  Future<void> performLogin({
    required BuildContext context,
    required Function goToChat,
    required Function updateUI,
  }) async {
    String email = emailController.text.trim();
    String password = passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both Email and Password")),
      );
      return;
    }

    isLoading = true;
    updateUI(); // Show loading spinner

    var user = await auth.login(email, password);

    isLoading = false;
    updateUI(); // Hide loading spinner

    if (user != null) {
      clearFields();
      goToChat(); // Move to next screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Failed: Incorrect email or password"), backgroundColor: Colors.red),
      );
    }
  }
}
