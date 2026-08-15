import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database/api_services.dart';
import '../../database/database_service.dart';
import '../../models/message.dart';
import 'package:ai_chatbot/services/voice_assitant.dart';

class ChatScreenLogic {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ApiService apiService = ApiService();
  final VoiceAssistant voice = VoiceAssistant();

  bool isTyping = false;
  String? currentChatId; // This persists across screen changes
  String streamingResponse = "";
  List<String> currentSuggestions = [];

  Future<void> loadLastChat(DatabaseService dbService, Function updateUI) async {
    // Look for the last chat in the database
    String? lastId = await dbService.getLatestChatId();
    if (lastId != null) {
      currentChatId = lastId;
      updateUI(); // Refresh the screen to show the bubbles
    }
  }

  void refreshSuggestions() {
    currentSuggestions = (List<String>.from([
      "Open Chrome",
      "Take Screenshot",
      "Increase Volume",
      "File Explorer",
    ])..shuffle()).toList();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }

  void toggleVoiceTyping(Function updateUI) {
    voice.toggleVoice(messageController, updateUI);
  }

  Future<void> handleSendMessage({
    String? text,
    required DatabaseService dbService,
    required Function updateUI,
  }) async {
    if (isTyping) {
      apiService.stopResponse();
      isTyping = false;
      streamingResponse = "";
      updateUI();
      return;
    }

    String msgText = text ?? messageController.text.trim();
    if (msgText.isEmpty) return;

    if (voice.isListening) voice.reset();
    messageController.clear();

    // MEMORY: Re-use currentChatId if it exists, only create if null
    if (currentChatId == null) {
      currentChatId = await dbService.createNewChat();
      await dbService.updateChatTitle(currentChatId!, msgText);
    }

    await dbService.saveMessage(
      currentChatId!,
      Message(text: msgText, isUser: true),
    );
    isTyping = true;
    streamingResponse = "";
    updateUI();

    var userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(dbService.uid)
        .get();
    var userData = userSnap.data() as Map<String, dynamic>;

    // --- ALL 9 PC COMMANDS INCLUDED ---
    String contextPrompt = """You are NEXA. User info: ${userData['status']}.
    MANDATORY RULES: You MUST end your response with the exact tag for these PC actions:
    1. Open File Explorer: [CMD:open_explorer]
    2. Open Google Chrome: [CMD:open_chrome]
    3. Take Screenshot: [CMD:screenshot]
    4. Volume Up: [CMD:volume_up]
    5. Volume Down: [CMD:volume_down]
    6. Brightness Up: [CMD:brightness_up]
    7. Brightness Down: [CMD:brightness_down]
    8. Close Active Window: [CMD:close_window]
    9. Power Off PC: [CMD:power_off]""";

    var messageDocs = await dbService.getMessagesOnce(currentChatId!);
    List<Message> history = messageDocs
        .map((doc) => Message(text: doc['text'], isUser: doc['isUser']))
        .toList();

    try {
      await for (var word in apiService.sendMessageStream([
        Message(text: contextPrompt, isUser: false),
        ...history,
      ])) {
        if (!isTyping) break;
        streamingResponse += word;
        updateUI();
        scrollToBottom();
      }

      // PC COMMAND SCANNER
      if (streamingResponse.contains("[CMD:")) {
        final match = RegExp(
          r"\[CMD:\s*(.*?)\s*\]",
        ).firstMatch(streamingResponse);
        if (match != null) {
          String action = match.group(1)!.trim().toLowerCase();
          await FirebaseFirestore.instance.collection('commands').add({
            'action': action,
            'timestamp': FieldValue.serverTimestamp(),
          });
          streamingResponse = streamingResponse.split("[CMD:")[0].trim();
        }
      }

      if (isTyping && streamingResponse.isNotEmpty) {
        await dbService.saveMessage(
          currentChatId!,
          Message(text: streamingResponse, isUser: false),
        );
      }
    } catch (e) {
      print("Error: $e");
    }

    isTyping = false;
    streamingResponse = "";
    updateUI();
  }
}
