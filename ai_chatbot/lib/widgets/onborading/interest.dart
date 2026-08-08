import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class Step4Interests extends StatelessWidget {
  final List<String> selectedInterests;
  final Function(String) onToggle;

  const Step4Interests({
    super.key,
    required this.selectedInterests,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    List<String> topics = [
      "Programming",
      "AI",
      "Business",
      "Design",
      "Science",
      "Music",
      "Fitness",
      "History",
    ];
    return Column(
      children: [
        const Text(
          "What interests you?",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          children: topics
              .map(
                (t) => FilterChip(
                  label: Text(t),
                  selected: selectedInterests.contains(t),
                  onSelected: (_) => onToggle(t),

                  // COLORS
                  selectedColor: AppTheme.limeGreen,
                  checkmarkColor: AppTheme.darkBackground, // Dark checkmark
                  backgroundColor: Colors.white.withValues(alpha: 0.05),

                  // TEXT STYLE SWITCHING
                  labelStyle: TextStyle(
                    color: selectedInterests.contains(t)
                        ? AppTheme.darkBackground
                        : Colors.white70,
                    fontWeight: selectedInterests.contains(t)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),

                  // SHAPE
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: selectedInterests.contains(t)
                          ? AppTheme.limeGreen
                          : Colors.white10,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
