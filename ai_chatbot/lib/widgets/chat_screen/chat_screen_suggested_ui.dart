import 'package:flutter/material.dart';

class SuggestedUI extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onTapSuggestion;

  const SuggestedUI({super.key, required this.suggestions, required this.onTapSuggestion});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 90),
          Image.asset('lib/assets/drawer-icon.png', width: 90),
          const SizedBox(height: 25),
          const Text(
            "Welcome! Try asking",
            style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Create the suggestion buttons
          for (var text in suggestions)
            GestureDetector(
              onTap: () => onTapSuggestion(text),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Center(
                  child: Text(text, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
