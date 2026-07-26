import 'package:flutter/material.dart';
import '../../database/auth_services.dart';

class RegisterLogic {
  // 1. Boxes to hold what the user types
  final TextEditingController fName = TextEditingController();
  final TextEditingController lName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController pass = TextEditingController();

  bool isLoading = false;
  final AuthService auth = AuthService.instance;

  // 2. Function to clean up memory when leaving the screen
  void dispose() {
    fName.dispose();
    lName.dispose();
    phone.dispose();
    email.dispose();
    pass.dispose();
  }

  // 3. The actual "Register" action
  Future<void> performRegister({
    required BuildContext context,
    required Function updateUI,
    required Function goBack,
  }) async {
    // Check if anything is empty
    if (email.text.isEmpty || pass.text.isEmpty || fName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    isLoading = true;
    updateUI(); // Show loading spinner

    // Ask Firebase to create the user
    final user = await auth.register(
      email.text.trim(),
      pass.text.trim(),
      fName.text.trim(),
      lName.text.trim(),
      phone.text.trim(),
    );

    isLoading = false;
    updateUI(); // Hide loading spinner

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Success! Please Login.")),
      );
      goBack(); // Take user back to Login page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Failed. Try again.")),
      );
    }
  }
}
