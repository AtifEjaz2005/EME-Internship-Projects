import 'package:flutter/material.dart';
import '../../database/database_service.dart';
import '../../models/message.dart';
import 'chat_bubble.dart';
import 'package:ai_chatbot/backend/chat_screen/chat_screen_logic.dart';
import 'package:ai_chatbot/widgets/chat_screen/typing_bubble.dart';

class MessageList extends StatefulWidget {
  final String chatId;
  final DatabaseService dbService;
  final ScrollController scrollController;
  final VoidCallback onNewMessage;
  final ChatScreenLogic logic;
  final String? currentlySpeakingText;
  final VoidCallback refreshIcon;
  final bool isTyping;

  const MessageList({
    super.key,
    required this.chatId,
    required this.dbService,
    required this.scrollController,
    required this.onNewMessage,
    required this.logic,
    required this.currentlySpeakingText,
    required this.refreshIcon,
    required this.isTyping,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  // 1. This variable remembers how many messages we saw last time
  int _lastMessageCount = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.dbService.getMessages(widget.chatId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        var docs = snapshot.data!.docs;

         // 3. Scroll if a new message arrives OR if bot starts typing
        if (docs.length > _lastMessageCount || widget.isTyping) {
          _lastMessageCount = docs.length;
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onNewMessage());
        }

        return ListView.builder(
          controller: widget.scrollController,
          itemCount: docs.length + (widget.isTyping ? 1 : 0),
          itemBuilder: (context, index) {
             // 5. If we are at the end of the list and bot is typing, show the bubble
            if (index == docs.length) {
              return const TypingBubble();
            }

            var data = docs[index];
            return ChatBubble(
  message: Message(text: data['text'], isUser: data['isUser']),
  currentlySpeakingText: widget.currentlySpeakingText, // PASS THIS
  onSpeak: () => widget.logic.voice.toggleReadAloud(
    data['text'],
    widget.refreshIcon,
  ),
);
          },
        );
      },
    );
  }
}
