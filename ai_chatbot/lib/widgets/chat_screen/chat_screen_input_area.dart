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
    bool hasText = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                // DISBALE TEXT ENTRY while bot is typing OR while mic is recording
                enabled: !isTyping && (!isListening || isPaused),
                onChanged: onChanged,
                minLines: 1, maxLines: 2,
                style: TextStyle(color: (isListening || isTyping) ? Colors.white24 : Colors.white),
                decoration: InputDecoration(
                  hintText: isTyping ? "Generating..." : (isListening ? "Listening..." : "Ask anything..."),
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
                  // MIC ICON: Hidden while bot is responding
                  if (!isTyping)
                    IconButton(
                      onPressed: (hasText && !isListening) ? null : onMicTap,
                      icon: Icon(
                        !isListening ? Icons.mic_none_rounded : (isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                        color: isListening ? Colors.redAccent : (hasText ? Colors.white10 : Colors.white54),
                        size: 26,
                      ),
                    ),

                  // SEND/STOP ICON
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
