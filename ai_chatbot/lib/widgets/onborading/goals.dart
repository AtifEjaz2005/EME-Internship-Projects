import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class Step5Goals extends StatelessWidget {
  final List<String> selectedGoals;
  final Function(String) onToggle;

  const Step5Goals({super.key, required this.selectedGoals, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    List<String> goals = ["Learn Skills", "Career Growth", "Coding Help", "Writing", "Research", "Productivity"];
    return Column(
      children: [
        const Text("What are your goals?", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          children: goals.map((g) => FilterChip(
            label: Text(g),
            selected: selectedGoals.contains(g),
            onSelected: (_) => onToggle(g),
            selectedColor: AppTheme.limeGreen,
          )).toList(),
        ),
      ],
    );
  }
}
