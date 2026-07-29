import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../themes/app_theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // 1. Import the translator

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
          maxWidth: MediaQuery.of(context).size.width * 0.75,
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
        // 2. The "Translator" Widget
        child: MarkdownBody(
          data: message.text, // The raw text with symbols like # and *
          styleSheet: MarkdownStyleSheet(

            p: TextStyle(
              color: message.isUser ? AppTheme.darkBackground : Colors.white,
              fontSize: 16,
            ),

            // 2. Headings (h1 is biggest #, h2 is ##, h3 is ###)
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

            // 3. Bold (**text**) and Italic (*text*)
            strong: const TextStyle(fontWeight: FontWeight.bold),
            em: const TextStyle(fontStyle: FontStyle.italic),

            // 4. Lists (Bullet points and Numbered lists)
            listBullet: TextStyle(
              color: message.isUser ? AppTheme.darkBackground : Colors.white,
            ),
            listIndent: 20.0, // Space between bullet and text
            // 5. Inline Code (like `this`)
            code: TextStyle(
              backgroundColor: Colors.black54, // Dark box behind code
              color: AppTheme.limeGreen, // Green text for code
              fontFamily: 'monospace', // Coding font
            ),

            // 6. Code Blocks (the big boxes for programming code)
            codeblockDecoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),

            // 7. Links ([text](url))
            a: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),

            // 8. Blockquotes (the > symbol used for quoting)
            blockquote: const TextStyle(color: Colors.white70),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: AppTheme.limeGreen, width: 4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
