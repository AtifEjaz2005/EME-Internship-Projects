import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database/api_services.dart';
import '../../database/database_service.dart';
import '../../models/message.dart';
import 'package:ai_chatbot/services/voice_assitant.dart'; // Import the new Voice file

class ChatScreenLogic {
  // 1. Text and Scroll Controllers
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // 2. Services
  final ApiService apiService = ApiService();
  final VoiceAssistant voice = VoiceAssistant(); // Our new Voice Brain

  // 3. State Variables
  bool isTyping = false;
  String? currentChatId;
  List<String> currentSuggestions = [];

  // Default suggested messages
  final List<String> _allSuggestions = [
    "Hello! How can you help me today?",
    "Tell me an interesting fact about space.",
    "Write a short poem about technology.",
    "Give me some ideas for a healthy breakfast.",
    "Explain how Artificial Intelligence works.",
  ];

  // --- WELCOME SCREEN LOGIC ---
  void refreshSuggestions() {
    currentSuggestions = (List<String>.from(
      _allSuggestions,
    )..shuffle()).take(3).toList();
  }

  // --- SCROLLING LOGIC ---
  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // --- VOICE TYPING LOGIC ---
  // We simply tell the VoiceAssistant file to handle the hard work
  void toggleVoiceTyping(Function updateUI) {
    voice.toggleVoice(messageController, updateUI);
  }

  // --- SEND MESSAGE LOGIC ---
  Future<void> handleSendMessage({
    String? text,
    required DatabaseService dbService,
    required Function updateUI,
  }) async {
    String msgText = text ?? messageController.text.trim();
    if (msgText.isEmpty) return;

    if (voice.isListening) {
      voice.reset();
    }

    messageController.clear();

    if (isTyping) {
      apiService.stopResponse();
      isTyping = false;
      updateUI();
      return;
    }

    if (currentChatId == null) {
      currentChatId = await dbService.createNewChat();
      await dbService.updateChatTitle(currentChatId!, msgText);
    }

    await dbService.saveMessage(
      currentChatId!,
      Message(text: msgText, isUser: true),
    );

    isTyping = true;
    updateUI();

    // I. PERSONALIZATION: Fetch Onboarding Info
    // var userSnap = await FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(dbService.uid)
    //     .get();
    // var userData = userSnap.data() as Map<String, dynamic>;

    // FIXED: Changed 'u' to 'userData' to match the variable above
    String contextPrompt = """
... (keep your existing persona) ...

PC CONTROL RULES:
At the end of your response, you MUST include one of these tags if requested:
1. Open File Explorer: [CMD:open_explorer]
2. Open Chrome: [CMD:open_chrome]
3. Power Off PC: [CMD:power_off]
4. Increase Brightness: [CMD:brightness_up]
5. Decrease Brightness: [CMD:brightness_down]
6. Increase Volume: [CMD:volume_up]
7. Decrease Volume: [CMD:volume_down]
8. Take Screenshot: [CMD:screenshot]
9. Close Current Window: [CMD:close_window]

Example: If user says "it's too bright", say "No problem, dimming the screen now. [CMD:brightness_down]"
""";

    // J. MEMORY: Fetch Chat History
    var messageDocs = await dbService.getMessagesOnce(currentChatId!);
    List<Message> history = messageDocs
        .map((doc) => Message(text: doc['text'], isUser: doc['isUser']))
        .toList();

    // K. SEND EVERYTHING TO AI
    List<Message> fullConversation = [
      Message(text: contextPrompt, isUser: false),
      ...history,
    ];
    String response = await apiService.sendMessage(fullConversation);

    // --- NEW: PC COMMAND SCANNER ---
    if (response.contains("[CMD:")) {
      try {
        // Find the text between [CMD: and ] even if there are weird symbols
        final RegExp regex = RegExp(r"\[CMD:\s*(.*?)\s*\]");
        final match = regex.firstMatch(response);

        if (match != null) {
          String command = match.group(1)!.trim().toLowerCase();
          print("NEXA LOG: Writing Command to Firebase -> $command");

          // Write to Firebase
          await FirebaseFirestore.instance.collection('commands').add({
            'action': command,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        // Clean the response for the UI
        response = response.split("[CMD:")[0].trim();
      } catch (e) {
        print("NEXA ERROR: Command parsing failed -> $e");
      }
    }

    // L. SAVE AI RESPONSE to Firebase
    if (response != "Request stopped." && isTyping) {
      await dbService.saveMessage(
        currentChatId!,
        Message(text: response, isUser: false),
      );
    }

    isTyping = false;
    updateUI();
  }
}
