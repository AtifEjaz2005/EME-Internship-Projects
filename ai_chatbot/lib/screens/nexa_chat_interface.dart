import 'package:flutter/material.dart';
import '../backend/chat_screen/chat_screen_logic.dart';
import '../database/auth_services.dart';
import '../database/database_service.dart';
import '../themes/app_theme.dart';
import '../widgets/chat_screen/chat_screen_input_area.dart';
import '../widgets/chat_screen/message_list.dart';

class NexaChatInterface extends StatefulWidget {
  const NexaChatInterface({super.key});

  @override
  State<NexaChatInterface> createState() => _NexaChatInterfaceState();
}

class _NexaChatInterfaceState extends State<NexaChatInterface> {
  final ChatScreenLogic logic = ChatScreenLogic();
  late DatabaseService dbService;

  @override
  void initState() {
    super.initState();
    dbService = DatabaseService(uid: AuthService.instance.currentUserId);
    // Note: We don't refresh suggestions here because we want to see history
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.gradientBg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          elevation: 0,
          title: const Text("NEXA Assistant"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: logic.currentChatId == null
                  ? const Center(child: Text("How can I help you today?", style: TextStyle(color: Colors.white70)))
                  : MessageList(
                      chatId: logic.currentChatId!,
                      dbService: dbService,
                      scrollController: logic.scrollController,
                      logic: logic,
                      currentlySpeakingText: logic.voice.currentlySpeakingText,
                      isTyping: logic.isTyping,
                      onNewMessage: () => logic.scrollToBottom(),
                      refreshIcon: () => setState(() {}),
                    ),
            ),
            ChatInputArea(
              controller: logic.messageController,
              isTyping: logic.isTyping,
              isListening: logic.voice.isListening,
              isPaused: logic.voice.isPaused,
              onMicTap: () => logic.toggleVoiceTyping(() => setState(() {})),
              onSend: () => logic.handleSendMessage(
                dbService: dbService,
                updateUI: () => setState(() {}),
              ),
              onChanged: (text) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
