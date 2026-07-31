import 'package:flutter/material.dart';
import '../../database/api_services.dart';
import '../../database/database_service.dart';
import '../../models/message.dart';
import 'package:speech_to_text/speech_to_text.dart'; // 1. Import library
import 'package:flutter_tts/flutter_tts.dart'; // Import TTS

class ChatScreenLogic {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ApiService apiService = ApiService();
  final SpeechToText _speechToText = SpeechToText(); // 2. Create the Ear
  bool isListening = false; // 3. Tracks if we are currently recording
  final FlutterTts _tts = FlutterTts();
  String? currentlySpeakingText;

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

  void toggleVoiceTyping(Function updateUI) async {
    if (!isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        isListening = true;
        updateUI();

        _speechToText.listen(
          onResult: (result) {
            if (messageController.text != result.recognizedWords) {
              messageController.text = result.recognizedWords;
              messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: messageController.text.length),
              );
              updateUI(); // Only refresh if text actually changed
            }
          },
          listenOptions: SpeechListenOptions(
            partialResults: true,
            listenMode: ListenMode.dictation,
          ),
        );
      }
    } else {
      stopListening(updateUI);
    }
  }

  Future<void> toggleSpeak(String text, Function updateUI) async {
    if (currentlySpeakingText == text) {
      // 1. STOP: If we click the same bubble, stop the voice
      await _tts.stop();
      currentlySpeakingText = null;
    } else {
      // 2. START: Stop any previous voice and start new one
      await _tts.stop();
      currentlySpeakingText = text;
      updateUI(); // Refresh icon to "No Line" immediately

      await _tts.speak(text);

      // 3. AUTO-RESET: When text ends, put the "Line" back
      _tts.setCompletionHandler(() {
        currentlySpeakingText = null;
        updateUI();
      });
    }
    updateUI(); // Final refresh to ensure toggle happens
  }

  // Helper to stop listening cleanly
  void stopListening(Function updateUI) {
    isListening = false;
    _speechToText.stop();
    updateUI();
  }

  // 2. READ MESSAGE LOUDLY
  Future<void> speak(String text) async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  // 3. STOP TTS (Optional, if user wants to silence it)
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  // The logic for sending or stopping a message
  Future<void> handleSendMessage({
    String? text,
    required DatabaseService dbService,
    required Function updateUI,
  }) async {
    // NEW: If the user is currently speaking (mic is red), stop it first
    if (isListening) {
      stopListening(updateUI);
    }

    if (isTyping) {
      apiService.stopResponse();
      isTyping = false;
      updateUI();
      return;
    }

    String msgText = text ?? messageController.text.trim();
    if (msgText.isEmpty) return;

    if (currentChatId == null) {
      currentChatId = await dbService.createNewChat();
      await dbService.updateChatTitle(currentChatId!, msgText);
    }

    Message userMsg = Message(text: msgText, isUser: true);
    messageController.clear();
    await dbService.saveMessage(currentChatId!, userMsg);

    isTyping = true;
    updateUI();

    // Context Fix: Fetch full history so the AI remembers past jokes/topics
    var messageDocs = await dbService.getMessagesOnce(currentChatId!);

    List<Message> history = messageDocs.map((doc) {
      return Message(text: doc['text'], isUser: doc['isUser']);
    }).toList();

    String response = await apiService.sendMessage(history);

    if (response != "Request stopped." && isTyping) {
      await dbService.saveMessage(
        currentChatId!,
        Message(text: response, isUser: false),
      );
    }

    isTyping = false;
    updateUI(); // This ensures the Send button turns green again
  }
}
