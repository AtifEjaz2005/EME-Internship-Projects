import 'package:flutter/material.dart';
import '../../database/database_service.dart';
import '../../models/message.dart';
import 'chat_bubble.dart';

class MessageList extends StatelessWidget {
  final String chatId;
  final DatabaseService dbService;
  final ScrollController scrollController;
  final VoidCallback onNewMessage;

  const MessageList({
    super.key,
    required this.chatId,
    required this.dbService,
    required this.scrollController,
    required this.onNewMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // 1. Tell the widget which chat folder to watch
      stream: dbService.getMessages(chatId),
      builder: (context, snapshot) {
        // 2. If there is no data yet, show nothing
        if (!snapshot.hasData) return const SizedBox();

        var docs = snapshot.data!.docs;

        // 3. Every time a new message arrives, tell the screen to scroll down
        WidgetsBinding.instance.addPostFrameCallback((_) => onNewMessage());

        // 4. Build the actual list of bubbles
        return ListView.builder(
          controller: scrollController,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index];
            return ChatBubble(
              message: Message(
                text: data['text'],
                isUser: data['isUser'],
              ),
            );
          },
        );
      },
    );
  }
}
