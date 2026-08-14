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
  String streamingResponse = "";

  void refreshSuggestions() {
    currentSuggestions = (List<String>.from(["Open Chrome", "Take screenshot", "Volume Up", "Turn off PC"])..shuffle()).take(4).toList();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }

  void toggleVoiceTyping(Function updateUI) {
    voice.toggleVoice(messageController, updateUI);
  }

  Future<void> handleSendMessage({String? text, required DatabaseService dbService, required Function updateUI}) async {
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

    if (currentChatId == null) {
      currentChatId = await dbService.createNewChat();
      await dbService.updateChatTitle(currentChatId!, msgText);
    }

    await dbService.saveMessage(currentChatId!, Message(text: msgText, isUser: true));
    isTyping = true;
    streamingResponse = "";
    updateUI();

    var userSnap = await FirebaseFirestore.instance.collection('users').doc(dbService.uid).get();
    var userData = userSnap.data() as Map<String, dynamic>;

    String contextPrompt = "You are NEXA. User: ${userData['status']}. MANDATORY PC tags: [CMD:open_explorer], [CMD:open_chrome], [CMD:screenshot], [CMD:volume_up], [CMD:volume_down], [CMD:power_off], [CMD:brightness_up], [CMD:brightness_down], [CMD:close_window].";

    var messageDocs = await dbService.getMessagesOnce(currentChatId!);
    List<Message> history = messageDocs.map((doc) => Message(text: doc['text'], isUser: doc['isUser'])).toList();

    try {
      await for (var word in apiService.sendMessageStream([Message(text: contextPrompt, isUser: false), ...history])) {
        if (!isTyping) break;
        streamingResponse += word;
        updateUI();
        scrollToBottom();
      }

      if (streamingResponse.contains("[CMD:")) {
        final match = RegExp(r"\[CMD:\s*(.*?)\s*\]").firstMatch(streamingResponse);
        if (match != null) {
          await FirebaseFirestore.instance.collection('commands').add({
            'action': match.group(1)!.trim().toLowerCase(),
            'timestamp': FieldValue.serverTimestamp(),
          });
          streamingResponse = streamingResponse.split("[CMD:")[0].trim();
        }
      }

      if (isTyping && streamingResponse.isNotEmpty) {
        await dbService.saveMessage(currentChatId!, Message(text: streamingResponse, isUser: false));
      }
    } catch (e) { print("Error: $e"); }

    isTyping = false;
    streamingResponse = "";
    updateUI();
  }
}
