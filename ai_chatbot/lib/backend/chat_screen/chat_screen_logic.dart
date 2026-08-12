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
  String? currentChatId;
  List<String> currentSuggestions = [];

  void refreshSuggestions() {
    currentSuggestions = (List<String>.from([
      "Open Chrome",
      "Take screenshot",
      "Mute volume",
      "Turn off PC",
    ])..shuffle()).take(3).toList();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }

  Future<void> handleSendMessage({
    String? text,
    required DatabaseService dbService,
    required Function updateUI,
  }) async {
    // A. Handle "Stop Button" during AI response
    if (isTyping) {
      apiService.stopResponse();
      isTyping = false;
      updateUI();
      return;
    }

    // B. Grab text and handle Mic State
    String msgText = text ?? messageController.text.trim();
    if (msgText.isEmpty) return;

    if (voice.isListening) {
      voice.reset();
    }
    messageController.clear();

    // C. Initialize Chat ID
    if (currentChatId == null) {
      currentChatId = await dbService.createNewChat();
      await dbService.updateChatTitle(currentChatId!, msgText);
    }

    // D. Save User Message
    await dbService.saveMessage(
      currentChatId!,
      Message(text: msgText, isUser: true),
    );
    isTyping = true;
    updateUI();

    try {
      // E. Fetch Profile Context (Personalization)
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(dbService.uid)
          .get();
      var u = userSnap.data() as Map<String, dynamic>;
      String contextPrompt =
          "You are NEXA. User is ${u['status']} from ${u['country']}. PC CMDs: [CMD:open_chrome], [CMD:screenshot], [CMD:open_explorer], [CMD:volume_up], [CMD:volume_down], [CMD:brightness_up], [CMD:brightness_down], [CMD:close_window], [CMD:power_off].";

      // F. Fetch History (Context)
      var messageDocs = await dbService.getMessagesOnce(currentChatId!);
      List<Message> history = messageDocs
          .map((doc) => Message(text: doc['text'], isUser: doc['isUser']))
          .toList();

      // G. Call AI
      String response = await apiService.sendMessage([
        Message(text: contextPrompt, isUser: false),
        ...history,
      ]);

      // H. Scan for PC Commands
      if (response.contains("[CMD:")) {
        final RegExp regex = RegExp(r"\[CMD:\s*(.*?)\s*\]");
        final match = regex.firstMatch(response);
        if (match != null) {
          await FirebaseFirestore.instance.collection('commands').add({
            'action': match.group(1)!.trim().toLowerCase(),
            'timestamp': FieldValue.serverTimestamp(),
          });
          response = response.split("[CMD:")[0].trim();
        }
      }

      // I. Save AI Response
      if (response != "Request stopped." && isTyping) {
        await dbService.saveMessage(
          currentChatId!,
          Message(text: response, isUser: false),
        );
      }
    } catch (e) {
      print("SEND ERROR: $e");
    }

    isTyping = false;
    updateUI();
  }

  void toggleVoiceTyping(Function updateUI) {
    // This talks to the VoiceAssistant service
    voice.toggleVoice(messageController, updateUI);
  }
}
