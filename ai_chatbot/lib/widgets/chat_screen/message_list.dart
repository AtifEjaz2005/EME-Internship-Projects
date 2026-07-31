import 'package:flutter/material.dart';
import '../../database/database_service.dart';
import '../../models/message.dart';
import 'chat_bubble.dart';
import 'package:ai_chatbot/backend/chat_screen/chat_screen_logic.dart';

class MessageList extends StatefulWidget {
  final String chatId;
  final DatabaseService dbService;
  final ScrollController scrollController;
  final VoidCallback onNewMessage;
  final ChatScreenLogic logic;
  final String? currentlySpeakingText;
  final VoidCallback refreshIcon;

  const MessageList({
    super.key,
    required this.chatId,
    required this.dbService,
    required this.scrollController,
    required this.onNewMessage,
    required this.logic,
    required this.currentlySpeakingText,
    required this.refreshIcon,
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

        // 2. ONLY SCROLL IF A NEW MESSAGE ARRIVED
        // We compare the current count with the last count we remembered
        if (docs.length > _lastMessageCount) {
          _lastMessageCount = docs.length; // Update the memory

          // Tell the screen to scroll down only for this new message
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onNewMessage());
        }

        return ListView.builder(
          controller: widget.scrollController,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index];
            return ChatBubble(
              message: Message(text: data['text'], isUser: data['isUser']),
              currentlySpeakingText: widget.currentlySpeakingText,
              // When clicking speak, it refreshes the icon but doesn't scroll
              onSpeak: () => widget.logic.toggleSpeak(
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
