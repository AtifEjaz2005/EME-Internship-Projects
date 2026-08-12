import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final VoidCallback onSend;
  final bool isListening;
  final bool isPaused;
  final VoidCallback onMicTap;
  final Function(String) onChanged;

  const ChatInputArea({
    super.key, required this.controller, required this.isTyping,
    required this.onSend, required this.isListening, required this.onMicTap,
    required this.onChanged, required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    // Mutual Exclusivity Logic
    bool hasManualText = controller.text.trim().isNotEmpty && !isListening;

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                // LOCK: Disable keyboard if mic is actively hearing (unless paused)
                enabled: !isListening || isPaused,
                onChanged: onChanged,
                minLines: 1, maxLines: 2,
                style: TextStyle(color: (isListening && !isPaused) ? Colors.white24 : Colors.white),
                decoration: InputDecoration(
                  hintText: isListening ? (isPaused ? "Paused..." : "Listening...") : "Ask anything...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5, right: 8),
              child: Row(
                children: [
                  IconButton(
                    // LOCK: Disable Mic if user is typing manually
                    onPressed: hasManualText ? null : onMicTap,
                    icon: Icon(
                      !isListening ? Icons.mic_none_rounded : (isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                      color: isListening ? Colors.redAccent : (hasManualText ? Colors.white10 : Colors.white54),
                      size: 26,
                    ),
                  ),
                  IconButton(
                    onPressed: onSend,
                    icon: Icon(
                      // TOGGLE: Change to Stop Circle while generating
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
