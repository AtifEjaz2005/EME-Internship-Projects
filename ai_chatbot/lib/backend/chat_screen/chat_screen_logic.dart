import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database/api_services.dart';
import '../../database/database_service.dart';
import '../../models/message.dart';

class ChatScreenLogic {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ApiService apiService = ApiService();
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool isTyping = false;
  bool isListening = false;
  bool isPaused = false;
  String? currentChatId;
  String? currentlySpeakingText;

  // This acts as the "Memory" for previous sessions
  String _textHistory = "";

  void toggleVoiceTyping(Function updateUI) async {
    // 1. MANUAL PAUSE: Clicked while recording
    if (isListening && !isPaused) {
      isPaused = true;
      _textHistory = messageController.text; // Save current progress to memory
      await _speechToText.stop();
      updateUI();
      return;
    }

    // 2. RESUME: Clicked while paused
    if (isPaused) {
      isPaused = false;
      _startListeningLoop(updateUI);
      return;
    }

    // 3. START FRESH: Clicked while mic was off
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        // If engine stops naturally due to silence, just wake it back up
        // WITHOUT adding to history again (This prevents the doubling issue)
        if (status == 'done' && isListening && !isPaused) {
          _startListeningLoop(updateUI);
        }
      },
    );

    if (available) {
      isListening = true;
      isPaused = false;
      _textHistory = ""; // Clear memory for new session
      messageController.clear();
      _startListeningLoop(updateUI);
    }
  }

  void _startListeningLoop(Function updateUI) {
    _speechToText.listen(
      onResult: (result) {
        // Combine saved history with new words from current session
        String space = _textHistory.isNotEmpty ? " " : "";
        messageController.text = '$_textHistory$space${result.recognizedWords}'
            .trim();

        // --- FIX: REAL-TIME AUTO SCROLL ---
        // This forces the cursor to the end, which pushes the TextField view down
        messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: messageController.text.length),
        );

        updateUI();
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 10),
      ),
    );
    updateUI();
  }

  // --- TEXT TO SPEECH (Voice Out) ---
  Future<void> toggleSpeak(String text, Function updateUI) async {
    if (currentlySpeakingText == text) {
      await _tts.stop();
      currentlySpeakingText = null;
    } else {
      await _tts.stop();
      currentlySpeakingText = text;
      updateUI();
      await _tts.speak(text);
      _tts.setCompletionHandler(() {
        currentlySpeakingText = null;
        updateUI();
      });
    }
    updateUI();
  }

  // --- SEND MESSAGE LOGIC ---
  Future<void> handleSendMessage({
    String? text,
    required DatabaseService dbService,
    required Function updateUI,
  }) async {
    // Grab text before resetting mic
    String msgText = text ?? messageController.text.trim();
    if (msgText.isEmpty) return;

    // Reset Microphone states immediately
    if (isListening) {
      stopRecordingCompletely();
    }

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

    // Clear everything for fresh start
    messageController.clear();
    _textHistory = "";

    isTyping = true;
    updateUI();

    var userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(dbService.uid)
        .get();
    var u = userSnap.data() as Map<String, dynamic>;

    String contextPrompt = "You are NEXA... Status: ${u['status']}...";

    var messageDocs = await dbService.getMessagesOnce(currentChatId!);
    List<Message> history = messageDocs
        .map((doc) => Message(text: doc['text'], isUser: doc['isUser']))
        .toList();

    String response = await apiService.sendMessage([
      Message(text: contextPrompt, isUser: false),
      ...history,
    ]);

    if (response != "Request stopped." && isTyping) {
      await dbService.saveMessage(
        currentChatId!,
        Message(text: response, isUser: false),
      );
    }

    isTyping = false;
    updateUI();
  }

  void stopRecordingCompletely() {
    isListening = false;
    isPaused = false;
    _textHistory = "";
    _speechToText.stop();
  }

  List<String> currentSuggestions = [];
  final List<String> _allSuggestions = [
    "Hello! How can you help me today?",
    "Tell me an interesting fact about space.",
    "Write a short poem about technology.",
    "Give me some ideas for a healthy breakfast.",
    "Explain how Artificial Intelligence works.",
  ];

  void refreshSuggestions() {
    currentSuggestions = (List<String>.from(
      _allSuggestions,
    )..shuffle()).take(4).toList();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
