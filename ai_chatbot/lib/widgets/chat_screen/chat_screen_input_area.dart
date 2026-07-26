import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final VoidCallback onSend;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.isTyping,
    required this.onSend
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Ask anything...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                ),
              ),
            ),
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
    );
  }
}
