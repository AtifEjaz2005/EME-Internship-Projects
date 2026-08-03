import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final VoidCallback onSend;
  final bool isListening;
  final VoidCallback onMicTap;
  final Function(String) onChanged;
  final bool isPaused;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.isTyping,
    required this.onSend,
    required this.isListening,
    required this.onMicTap,
    required this.onChanged,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    // Check if there is currently text in the box
    bool hasText = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          // Pushes buttons to the bottom of the 2nd line when expanded
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isListening || isPaused, // Allow editing if paused
                onChanged: onChanged,
                minLines: 1,
                maxLines: 2, // Limit height to 2 lines
                scrollPadding: EdgeInsets.zero,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: isListening
                      ? (isPaused ? "Paused" : "Listening...")
                      : "Ask anything...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 15,
                  ),
                ),
              ),
            ),

            // Use a small padding to keep icons centered vertically with the text
            Padding(
              padding: const EdgeInsets.only(bottom: 5, right: 8),
              child: Row(
                children: [
                  // --- THE MIC ICON BUTTON ---
                  IconButton(
                    onPressed: hasText ? null : onMicTap,
                    icon: Icon(
                      // THE ICON TOGGLE
                      !isListening
                          ? Icons.mic_none_rounded : (isPaused ? Icons.play_arrow_rounded: Icons.pause_rounded), // Resume or Pause

                      color: isListening ? Colors.redAccent : Colors.white54,
                      size: 28,
                    ),
                  ),

                  // --- THE SEND/STOP BUTTON ---
                  IconButton(
                    onPressed: onSend,
                    icon: Icon(
                      isTyping ? Icons.stop_circle_rounded : Icons.send_rounded,
                      color: isTyping ? Colors.redAccent : AppTheme.limeGreen,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
