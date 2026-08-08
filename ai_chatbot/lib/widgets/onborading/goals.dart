import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class Step5Goals extends StatelessWidget {
  final List<String> selectedGoals;
  final Function(String) onToggle;

  const Step5Goals({
    super.key,
    required this.selectedGoals,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // A list of professional and personal goals
    final List<String> goals = [
      "Learn New Skills",
      "Career Growth",
      "Interview Prep",
      "Coding Help",
      "Exam Prep",
      "Writing",
      "Research",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What do you want help with?",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Choose your goals so NEXA can focus on what matters most to you.",
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 25),

        // Use Expanded and SingleChildScrollView so the chips can scroll if they overflow
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10, // Horizontal space between chips
              runSpacing: 10, // Vertical space between lines
              children: goals.map((goal) {
                final bool isSelected = selectedGoals.contains(goal);

                return FilterChip(
                  label: Text(goal),
                  selected: isSelected,
                  onSelected: (_) => onToggle(goal),

                  // --- PREMIUM STYLING ---

                  // Text Style: Flipped colors when selected
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.darkBackground : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),

                  // Background Colors
                  selectedColor: AppTheme.limeGreen,
                  checkmarkColor: AppTheme.darkBackground, // Dark checkmark on green
                  backgroundColor: Colors.white.withValues(alpha: 0.05),

                  // Border and Shape
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected ? AppTheme.limeGreen : Colors.white10,
                      width: 1,
                    ),
                  ),

                  // Remove default shadow for a cleaner look
                  elevation: 0,
                  pressElevation: 0,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
