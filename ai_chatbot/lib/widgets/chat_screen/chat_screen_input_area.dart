import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final VoidCallback onSend;
  final bool isListening;
  final bool isPaused; // Passed from logic
  final VoidCallback onMicTap;
  final Function(String) onChanged;

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
    bool hasText = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // Inside the build method of ChatInputArea:
        child: Row(
          // This pushes buttons to the bottom of the 2nd line as requested
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                // Allow editing if mic is off or if it is paused
                enabled: !isListening || isPaused,
                onChanged: onChanged,
                minLines: 1,
                maxLines: 2, // Fixed at 2 lines
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: isListening
                      ? (isPaused ? "Paused..." : "Listening...")
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

            // --- ICON BUTTONS ---
            Padding(
              padding: const EdgeInsets.only(bottom: 5, right: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: hasText && !isListening ? null : onMicTap,
                    icon: Icon(
                      !isListening
                          ? Icons.mic_none_rounded
                          : (isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded),
                      color: isListening
                          ? Colors.redAccent
                          : (hasText ? Colors.white10 : Colors.white54),
                      size: 26,
                    ),
                  ),
                  IconButton(
                    onPressed: onSend,
                    icon: Icon(
                      isTyping ? Icons.stop_circle_rounded : Icons.send_rounded,
                      color: isTyping ? Colors.redAccent : AppTheme.limeGreen,
                      size: 30,
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
