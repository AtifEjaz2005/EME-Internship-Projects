import 'package:flutter/material.dart';
import '../../database/api_services.dart';
import '../../database/database_service.dart';
import '../../models/message.dart';

class ChatScreenLogic {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ApiService apiService = ApiService();

  bool isTyping = false;
  String? currentChatId;
  List<String> currentSuggestions = [];

  final List<String> _allSuggestions = [
    "Hello! How can you help me today?",
    "Tell me an interesting fact about space.",
    "Write a short poem about technology.",
    "Give me some ideas for a healthy breakfast.",
    "Explain how Artificial Intelligence works.",
  ];

  // Pick 3 random suggestions
  void refreshSuggestions() {
    currentSuggestions = (List<String>.from(_allSuggestions)..shuffle()).take(3).toList();
  }

  // Automatically move the screen to the bottom
  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // The logic for sending or stopping a message
  Future<void> handleSendMessage({
    String? text,
    required DatabaseService dbService,
    required Function updateUI,
  }) async {
    // If bot is typing, clicking the button stops it
    if (isTyping) {
      apiService.stopResponse();
      isTyping = false;
      updateUI();
      return;
    }

    String msgText = text ?? messageController.text.trim();
    if (msgText.isEmpty) return;

    bool isFirstMessage = false;
    if (currentChatId == null) {
      currentChatId = await dbService.createNewChat();
      isFirstMessage = true;
    }

    // Save User Message
    messageController.clear();
    await dbService.saveMessage(currentChatId!, Message(text: msgText, isUser: true));

    if (isFirstMessage) {
      await dbService.updateChatTitle(currentChatId!, msgText);
    }

    isTyping = true;
    updateUI(); // Tell the screen to show "Typing..."

    // Get AI Response
    String response = await apiService.sendMessage([Message(text: msgText, isUser: true)]);

    if (response != "Request stopped." && isTyping) {
      await dbService.saveMessage(currentChatId!, Message(text: response, isUser: false));
    }

    isTyping = false;
    updateUI(); // Hide "Typing..."
  }
}
