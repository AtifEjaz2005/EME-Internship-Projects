import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class Step3Status extends StatelessWidget {
  final Function(String) onSelect;
  final String currentStatus;
  const Step3Status({
    super.key,
    required this.onSelect,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    List<String> options = [
      "🎓 Student",
      "💼 Working Pro",
      "🧑‍💻 Freelancer",
      "🚀 Entrepreneur",
      "✨ Other",
    ];
    return Column(
      children: [
        const Text(
          "What best describes you?",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: options
                .map(
                  (opt) => GestureDetector(
                    onTap: () => onSelect(opt),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        // Selected = Green, Not Selected = Transparent Glass
                        color: currentStatus == opt
                            ? AppTheme.limeGreen
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: currentStatus == opt
                              ? AppTheme.limeGreen
                              : Colors.white10,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: currentStatus == opt
                            ? [
                                BoxShadow(
                                  color: AppTheme.limeGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 10,
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          // DARK text when selected, WHITE text when not
                          color: currentStatus == opt
                              ? AppTheme.darkBackground
                              : Colors.white,
                          fontWeight: currentStatus == opt
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
