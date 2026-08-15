import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final VoidCallback onSend;
  final bool isListening;
  final bool isPaused;
  final VoidCallback onMicTap;
  final VoidCallback onMicToggle;
  final VoidCallback onDelete;
  final Function(String) onChanged;

  const ChatInputArea({
    super.key, required this.controller, required this.isTyping,
    required this.onSend, required this.isListening, required this.onMicTap,
    required this.onChanged, required this.isPaused,
    required this.onDelete, required this.onMicToggle,
  });

  @override
  Widget build(BuildContext context) {
    bool hasText = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 25, top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. DELETE BUTTON (Fixed 52x52)
          if (isListening)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: SizedBox(
                width: 52, height: 52,
                child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.1)),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 24),
                ),
              ),
            ),

          // 2. MAIN TEXT INPUT
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(
                color: const Color(0xFF242526),
                borderRadius: BorderRadius.circular(26),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                enabled: !isTyping,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                maxLines: 2, minLines: 1,
                decoration: InputDecoration(
                  hintText: isListening ? (isPaused ? "Paused" : "Listening...") : "Ask Anything!",
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(width: 5), // Reduced Spacing

          // 3. PAUSE/RESUME BUTTON (Fixed 52x52)
          if (isListening)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: SizedBox(
                width: 52, height: 52,
                child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: AppTheme.limeGreen.withValues(alpha: 0.1)),
                  onPressed: onMicToggle,
                  icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: AppTheme.limeGreen, size: 28),
                ),
              ),
            ),

          // 4. MAIN ACTION BUTTON (Fixed 52x52)
          SizedBox(
            width: 52, height: 52,
            child: GestureDetector(
              onTap: onSend,
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppTheme.limeGreen, shape: BoxShape.circle),
                child: Icon(
                  isTyping ? Icons.stop_rounded : (hasText || isListening ? Icons.send_rounded : Icons.mic_rounded),
                  color: Colors.black, size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
