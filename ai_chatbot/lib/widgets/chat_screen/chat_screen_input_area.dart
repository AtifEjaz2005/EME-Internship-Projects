import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final VoidCallback onSend;
  final bool isListening;
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
                // LOCK 1: Disable typing if we are listening to voice
                enabled: !isListening,
                onChanged: onChanged,
                minLines: 1,
                maxLines: 2,
                style: TextStyle(
                  // Dim the text color if the box is locked
                  color: isListening ? Colors.white38 : Colors.white,
                ),
                decoration: InputDecoration(
                  // Change hint text to explain why it's locked
                  hintText: isListening ? "Listening..." : "Ask anything...",
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
                    // LOCK 2: If user typed text, mic becomes unclickable (null)
                    onPressed: hasText ? null : onMicTap,
                    icon: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      // Change color to very dark if disabled (hasText)
                      color: hasText
                          ? Colors.white10
                          : (isListening ? Colors.redAccent : Colors.white54),
                      size: 26,
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
