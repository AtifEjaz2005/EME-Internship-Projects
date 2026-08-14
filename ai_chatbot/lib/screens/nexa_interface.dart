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
    widget.logic.voice.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          elevation: 0, centerTitle: true,
          title: const Text("NEXA ASSISTANT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.limeGreen),
              onPressed: () {
                setState(() {
                  widget.logic.currentChatId = null;
                  widget.logic.refreshSuggestions();
                });
              },
            ),
          ],
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
                      padding: const EdgeInsets.only(top: 20),
                      child: MessageList(
                        chatId: widget.logic.currentChatId!,
                        dbService: widget.dbService,
                        scrollController: widget.logic.scrollController,
                        logic: widget.logic,
                        isTyping: widget.logic.isTyping,
                        streamingText: widget.logic.streamingResponse,
                        currentlySpeakingText: widget.logic.voice.currentlySpeakingText,
                        onNewMessage: () => widget.logic.scrollToBottom(),
                        refreshIcon: () => setState(() {}),
                      ),
                    ),
            ),
            ChatInputArea(
              controller: widget.logic.messageController,
              isTyping: widget.logic.isTyping,
              isListening: widget.logic.voice.isListening,
              isPaused: widget.logic.voice.isPaused,
              // FIX: Now correctly triggers the mic start/pause/resume
              onMicTap: () => widget.logic.toggleVoiceTyping(() => setState(() {})),
              onMicToggle: () => widget.logic.toggleVoiceTyping(() => setState(() {})),
              onDelete: () {
                setState(() { widget.logic.voice.reset(); widget.logic.messageController.clear(); });
              },
              onSend: () {
                // If box is empty and not listening, the big button acts as Record
                if (widget.logic.messageController.text.isEmpty && !widget.logic.voice.isListening) {
                   widget.logic.toggleVoiceTyping(() => setState(() {}));
                } else {
                   widget.logic.handleSendMessage(dbService: widget.dbService, updateUI: () => setState(() {}));
                }
              },
              onChanged: (text) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
