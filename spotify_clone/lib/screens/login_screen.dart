import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spotify_clone/services/auth_service.dart';
import '../themes/app_colors.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.waves_rounded,
              color: AppColors.primaryGreen,
              size: 80,
            ), // Placeholder Logo
            const SizedBox(height: 24),
            const Text(
              "Welcome back",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              "Sign in to continue listening.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),

            TextField(
              decoration: InputDecoration(
                hintText: "Email",
                filled: true,
                fillColor: AppColors.surfaceDefault,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                filled: true,
                fillColor: AppColors.surfaceDefault,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: "Sign In", onPressed: () {}),
            const SizedBox(height: 20),

            const Text("or", style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 20),

            // Inside LoginScreen Column
            OutlinedButton(
              onPressed: () async {
                // Show a loading indicator if you want
                User? user = await AuthService().signInWithGoogle();

                if (user != null) {
                  // StreamBuilder in main.dart will automatically take you to MainWrapper
                  print("Logged in as ${user.displayName}");
                } else {
                  // Show error snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Google Sign-In Failed")),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.surfaceHigh),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // You can add a Google Logo Asset here
                  const Text(
                    "Continue with Google",
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),

            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              ),
              child: const Text(
                "Don't have an account? Sign up",
                style: TextStyle(color: AppColors.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
