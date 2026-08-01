import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class Step1Welcome extends StatelessWidget {
  final VoidCallback onNext;
  const Step1Welcome({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('lib/assets/drawer-icon.png', width: 100),
        const SizedBox(height: 30),
        const Text("Welcome to NEXA", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 15),
        const Text("Let's personalize your experience.", style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        _feature(Icons.psychology, "Personalized conversations"),
        _feature(Icons.track_changes, "Smarter recommendations"),
        _feature(Icons.rocket_launch, "Career & learning guidance"),
        const Spacer(),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.limeGreen, minimumSize: const Size(double.infinity, 55)),
          onPressed: onNext,
          child: const Text("Get Started →", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _feature(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(children: [Icon(icon, color: AppTheme.limeGreen), const SizedBox(width: 15), Text(text, style: const TextStyle(color: Colors.white))]),
  );
}
