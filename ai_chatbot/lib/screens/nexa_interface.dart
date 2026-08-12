import 'package:flutter/material.dart';
import '../backend/chat_screen/chat_screen_logic.dart';
import '../database/database_service.dart';
import '../themes/app_theme.dart';
import '../widgets/chat_screen/chat_screen_suggested_ui.dart';
import '../widgets/chat_screen/chat_screen_input_area.dart';
import '../widgets/chat_screen/message_list.dart';

class NexaInterface extends StatefulWidget {
  final ChatScreenLogic logic;
  final DatabaseService dbService;

  const NexaInterface({super.key, required this.logic, required this.dbService});

  @override
  State<NexaInterface> createState() => _NexaInterfaceState();
}

class _NexaInterfaceState extends State<NexaInterface> {

  @override
  void dispose() {
    // 1. Feature: Stop voice assistant completely when leaving to Dashboard
    widget.logic.voice.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.gradientBg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          elevation: 0, centerTitle: true,
          title: const Text("NEXA ASSISTANT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: widget.logic.currentChatId == null
                  ? SuggestedUI(
                      suggestions: widget.logic.currentSuggestions,
                      onTapSuggestion: (text) => widget.logic.handleSendMessage(
                        text: text, dbService: widget.dbService, updateUI: () => setState(() {}),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 20), // 2. Fix: Margin at top of bubbles
                      child: MessageList(
                        chatId: widget.logic.currentChatId!,
                        dbService: widget.dbService,
                        scrollController: widget.logic.scrollController,
                        logic: widget.logic,
                        isTyping: widget.logic.isTyping,
                        currentlySpeakingText: widget.logic.voice.currentlySpeakingText,
                        onNewMessage: () => widget.logic.scrollToBottom(),
                        refreshIcon: () => setState(() {}),
                      ),
                    ),
            ),

            // 3. The Input Area with all "Locking" and "Toggle" logic
            ChatInputArea(
              controller: widget.logic.messageController,
              isTyping: widget.logic.isTyping,
              isListening: widget.logic.voice.isListening,
              isPaused: widget.logic.voice.isPaused,
              onMicTap: () => widget.logic.toggleVoiceTyping(() => setState(() {})),
              onSend: () => widget.logic.handleSendMessage(
                dbService: widget.dbService, updateUI: () => setState(() {}),
              ),
              onChanged: (text) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
