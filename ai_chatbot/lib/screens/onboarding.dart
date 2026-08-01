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

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        "Step $currentStep of 5",
        style: const TextStyle(color: AppTheme.limeGreen),
      ),
      TextButton(
        onPressed: next,
        child: const Text("Skip", style: TextStyle(color: Colors.white38)),
      ),
    ],
  );

  Widget _buildNavButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextButton(
        onPressed: back,
        child: const Text(
          "← Previous",
          style: TextStyle(color: Colors.white38),
        ),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.limeGreen),
        onPressed: currentStep == 5 ? _finish : next,
        child: Text(
          currentStep == 5 ? "Finish ✓" : "Next →",
          style: const TextStyle(color: Colors.black),
        ),
      ),
    ],
  );

  void _finish() async {
    await DatabaseService(
      uid: AuthService.instance.currentUserId,
    ).saveOnboarding(userData);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const ChatScreen()),
      );
    }
  }
}
