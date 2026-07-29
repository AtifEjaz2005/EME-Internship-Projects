import 'package:flutter/material.dart';
import '../../database/api_services.dart';
import '../../database/database_service.dart';
import '../../models/message.dart';
import 'package:speech_to_text/speech_to_text.dart'; // 1. Import library

class ChatScreenLogic {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ApiService apiService = ApiService();
  final SpeechToText _speechToText = SpeechToText(); // 2. Create the Ear
  bool isListening = false; // 3. Tracks if we are currently recording

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
    currentSuggestions = (List<String>.from(
      _allSuggestions,
    )..shuffle()).take(3).toList();
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
    if (isTyping) {
      apiService.stopResponse();
      isTyping = false;
      updateUI();
      return;
    }

    String msgText = text ?? messageController.text.trim();
    if (msgText.isEmpty) return;

    // 1. If it's a new chat, create it first
    if (currentChatId == null) {
      currentChatId = await dbService.createNewChat();
      await dbService.updateChatTitle(currentChatId!, msgText);
    }

    // 2. Save your new message to the database
    Message userMsg = Message(text: msgText, isUser: true);
    messageController.clear();
    await dbService.saveMessage(currentChatId!, userMsg);

    isTyping = true;
    updateUI();

    // --- THE FIX STARTS HERE ---

    // 3. FETCH THE CONVERSATION HISTORY
    // We go to the database and grab all previous messages so the AI has "Memory"
    var messageDocs = await dbService.getMessagesOnce(currentChatId!);

    // Convert those database records into a List of Message objects
    List<Message> history = messageDocs.map((doc) {
      return Message(text: doc['text'], isUser: doc['isUser']);
    }).toList();

    // 4. SEND THE FULL HISTORY TO THE AI
    String response = await apiService.sendMessage(history);

    // --- THE FIX ENDS HERE ---

    if (response != "Request stopped." && isTyping) {
      await dbService.saveMessage(
        currentChatId!,
        Message(text: response, isUser: false),
      );
    }

    isTyping = false;
    updateUI();
  }

  // 4. Function to start listening
  void toggleVoiceTyping(Function updateUI) async {
    if (!isListening) {
      // Try to turn on the "Ear"
      bool available = await _speechToText.initialize();
      if (available) {
        isListening = true;
        updateUI(); // Show red mic in UI

        _speechToText.listen(
          onResult: (result) {
            // Put the spoken words into the text box
            messageController.text = result.recognizedWords;
            updateUI();
          },
        );
      }
    } else {
      // If already listening, turn it off
      isListening = false;
      _speechToText.stop();
      updateUI(); // Show normal mic in UI
    }
  }
}
