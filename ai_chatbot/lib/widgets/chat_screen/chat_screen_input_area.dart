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
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 25, top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isListening ? _buildRecordingUI() : _buildTextFieldUI(),
            ),
          ),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 52, height: 52,
              decoration: const BoxDecoration(color: AppTheme.limeGreen, shape: BoxShape.circle),
              child: Icon(
                // Toggle between Stop, Send, and Mic
                isTyping ? Icons.stop_rounded : (hasText || isListening ? Icons.send_rounded : Icons.mic_rounded),
                color: Colors.white, size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldUI() {
    return Container(
      key: const ValueKey("text"),
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: const Color(0xFF242526), borderRadius: BorderRadius.circular(30)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        enabled: !isTyping,
        style: const TextStyle(color: Colors.white),
        maxLines: 2, minLines: 1,
        decoration: const InputDecoration(
          hintText: "Message", hintStyle: TextStyle(color: Colors.white38),
          border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 1),
        ),
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      key: const ValueKey("rec"),
      child: Row(
        children: [
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 55, height: 55,
              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 30),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 55, padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: const Color(0xFF242526), borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: onMicToggle,
                    child: Row(
                      children: [
                        Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(isPaused ? "RESUME" : "PAUSE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
