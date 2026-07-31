import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../themes/app_theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onSpeak; // Added: Function to trigger voice
  final String? currentlySpeakingText;

  const ChatBubble({super.key, required this.message, this.onSpeak, this.currentlySpeakingText});

  @override
  Widget build(BuildContext context) {
    bool isThisTalking = currentlySpeakingText == message.text;
    return Column(
      // Align the whole column based on who is speaking
      crossAxisAlignment: message.isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: message.isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: message.isUser
                  ? AppTheme.limeGreen
                  : AppTheme.darkBackground,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(message.isUser ? 20 : 0),
                bottomRight: Radius.circular(message.isUser ? 0 : 20),
              ),
              border: !message.isUser
                  ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                  : null,
            ),
            child: MarkdownBody(
              data: message.text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: message.isUser
                      ? AppTheme.darkBackground
                      : Colors.white,
                  fontSize: 16,
                ),
                h1: TextStyle(
                  color: AppTheme.limeGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                h2: TextStyle(
                  color: AppTheme.limeGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                h3: TextStyle(
                  color: AppTheme.limeGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                em: const TextStyle(fontStyle: FontStyle.italic),
                listBullet: TextStyle(
                  color: message.isUser
                      ? AppTheme.darkBackground
                      : Colors.white,
                ),
                code: TextStyle(
                  backgroundColor: Colors.black54,
                  color: AppTheme.limeGreen,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),

        // ADDED: Speaker Icon only for the AI
        // Change the Icon part inside ChatBubble:
        if (!message.isUser)
          Padding(
            padding: const EdgeInsets.only(left: 25, bottom: 10),
            child: GestureDetector(
              onTap: onSpeak,
              child: Icon(
                // 3. Use the toggle icon logic
                isThisTalking ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: AppTheme.darkBackground,
                size: 22,
              ),
            ),
          ),
      ],
    );
  }
}
