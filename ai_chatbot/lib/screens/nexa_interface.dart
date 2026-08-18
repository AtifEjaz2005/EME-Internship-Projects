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
  const NexaInterface({
    super.key,
    required this.logic,
    required this.dbService,
  });

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
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Image.asset(
          'lib/assets/nexa_ai.png',
          height: 35, // Slightly smaller than dashboard to fit the inner screen look
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppTheme.limeGreen,
              size: 30,
            ),
            onPressed: () {
              setState(() {
                widget.logic.currentChatId = null; // Memory Wipe
                widget.logic.voice.reset();
                widget.logic.messageController.clear();
                widget.logic.refreshSuggestions();
                widget.logic.streamingResponse = "";
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
                      text: text,
                      dbService: widget.dbService,
                      updateUI: () => setState(() {}),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: MessageList(
                      chatId: widget.logic.currentChatId!,
                      dbService: widget.dbService,
                      scrollController: widget.logic.scrollController,
                      logic: widget.logic,
                      isTyping: widget.logic.isTyping,
                      streamingText: widget.logic.streamingResponse,
                      currentlySpeakingText:
                          widget.logic.voice.currentlySpeakingText,
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
            onMicTap: () =>
                widget.logic.toggleVoiceTyping(() => setState(() {})),
            onMicToggle: () =>
                widget.logic.toggleVoiceTyping(() => setState(() {})),
            onDelete: () {
              setState(() {
                widget.logic.voice.reset();
                widget.logic.messageController.clear();
              });
            },
            onSend: () {
              // PRIORITY 1: STOP AI
              if (widget.logic.isTyping) {
                widget.logic.handleSendMessage(
                  dbService: widget.dbService,
                  updateUI: () => setState(() {}),
                );
              }
              // PRIORITY 2: SEND MESSAGE
              else if (widget.logic.messageController.text.isNotEmpty ||
                  widget.logic.voice.isListening) {
                widget.logic.handleSendMessage(
                  dbService: widget.dbService,
                  updateUI: () => setState(() {}),
                );
              }
              // PRIORITY 3: RECORD
              else {
                widget.logic.toggleVoiceTyping(() => setState(() {}));
              }
            },
            onChanged: (text) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
