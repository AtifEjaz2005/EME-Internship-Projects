import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../themes/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      // User messages on the right, Bot messages on the left
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          // COLORS UPDATED:
          color: message.isUser ? AppTheme.limeGreen : AppTheme.darkBackground,

          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            // Distinctive corners for User vs Bot
            bottomLeft: Radius.circular(message.isUser ? 20 : 0),
            bottomRight: Radius.circular(message.isUser ? 0 : 20),
          ),
          // Subtle border for the bot bubble so it stands out against the gradient
          border: !message.isUser
              ? Border.all(color: Colors.white.withValues(alpha: 0.1))
              : null,
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 16,
            // TEXT COLOR CONTRAST:
            // Dark text on Lime Green, White text on Dark background
            color: message.isUser ? AppTheme.darkBackground : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
