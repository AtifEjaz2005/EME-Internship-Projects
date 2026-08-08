import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../database/database_service.dart';
import '../database/auth_services.dart';
import 'package:ai_chatbot/widgets/onborading/welcome.dart';
import 'package:ai_chatbot/widgets/onborading/profile.dart';
import 'package:ai_chatbot/widgets/onborading/goals.dart';
import 'package:ai_chatbot/widgets/onborading/interest.dart';
import 'package:ai_chatbot/widgets/onborading/status.dart';
import 'chat_screen.dart';
import 'package:ai_chatbot/models/onboarding_model.dart';

class OnboardingMain extends StatefulWidget {
  const OnboardingMain({super.key});
  @override
  State<OnboardingMain> createState() => _OnboardingMainState();
}

class _OnboardingMainState extends State<OnboardingMain> {
  int currentStep = 1;
  final OnboardingModel userData = OnboardingModel();

  void next() {
    if (currentStep < 5) {
      setState(() => currentStep++);
    }
  }

  void back() {
    if (currentStep > 1) {
      setState(() => currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.gradientBg,
        child: Center(child: _buildGlassCard(child: _getStepWidget())),
      ),
    );
  }

  Widget _getStepWidget() {
    switch (currentStep) {
      case 1:
        return Step1Welcome(onNext: next);
      case 2:
        return Step2Profile(
          selectedAge: userData.age,
          selectedCountry: userData.country,
          onAgeSelected: (val) => setState(() => userData.age = val),
          onCountrySelected: (val) => setState(() => userData.country = val),
        );
      case 3:
        return Step3Status(
          currentStatus: userData.status,
          onSelect: (val) => setState(() => userData.status = val),
        );
      case 4:
        return Step4Interests(
          selectedInterests: userData.interests,
          onToggle: (t) => setState(
            () => userData.interests.contains(t)
                ? userData.interests.remove(t)
                : userData.interests.add(t),
          ),
        );
      case 5:
        return Step5Goals(
          selectedGoals: userData.goals,
          onToggle: (g) => setState(
            () => userData.goals.contains(g)
                ? userData.goals.remove(g)
                : userData.goals.add(g),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: 450,
      height: 600,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          if (currentStep > 1) _buildHeader(),
          Expanded(child: child),
          if (currentStep > 1) _buildNavButtons(),
        ],
      ),
    );
  }

  // --- HEADER SECTION (Step Indicator & Skip) ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Step Indicator Styled as a Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.limeGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.limeGreen.withValues(alpha: 0.3)),
            ),
            child: Text(
              "STEP $currentStep OF 5",
              style: const TextStyle(
                color: AppTheme.limeGreen,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Skip Button - Made more visible with White70
          if (currentStep < 5)
            TextButton(
              onPressed: next,
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text(
                "Skip",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }

 Widget _buildNavButtons() => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // PREVIOUS BUTTON: Now uses an Outlined style for high contrast
            if (currentStep > 1)
              OutlinedButton(
                onPressed: back,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                child: const Text(
                  "Previous",
                  style: TextStyle(
                    color: Colors.white, // Pure white for best visibility
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const SizedBox(), // Keeps the "Next" button on the right

            // NEXT / FINISH BUTTON: Solid Lime Green with Dark Text
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.limeGreen,
                foregroundColor: AppTheme.darkBackground, // Dark text on green background
                elevation: 8,
                shadowColor: AppTheme.limeGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: currentStep == 5 ? _finish : next,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentStep == 5 ? "Finish ✓" : "Next",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  void _finish() async {
    // 1. Save all the data + set 'hasCompletedOnboarding' to true
    await DatabaseService(
      uid: AuthService.instance.currentUserId,
    ).saveOnboarding(userData);

    // 2. Move to Chat Screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const ChatScreen()),
      );
    }
  }
}
