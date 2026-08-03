import 'package:flutter/material.dart';
import '../../database/api_services.dart';
import '../../database/database_service.dart';
import '../../models/message.dart';
import 'package:speech_to_text/speech_to_text.dart'; // 1. Import library
import 'package:flutter_tts/flutter_tts.dart'; // Import TTS
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreenLogic {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ApiService apiService = ApiService();
  final SpeechToText _speechToText = SpeechToText(); // 2. Create the Ear
  bool isListening = false; // 3. Tracks if we are currently recording
  final FlutterTts _tts = FlutterTts();
  String? currentlySpeakingText;
  bool isPaused = false;
  String _finalTranscript = ""; // To track if we are in "Pause" mode

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
    // 1. If currently listening -> CLICK TO PAUSE
    if (isListening && !isPaused) {
      isPaused = true;
      _speechToText.stop(); // Stop the engine
      updateUI();
      return;
    }

    // 2. If already paused -> CLICK TO RESUME
    if (isPaused) {
      isPaused = false;
      _startListeningLoop(updateUI); // Restart the engine
      return;
    }

    // 3. START FRESH (First time clicking)
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        // If engine stops because you paused to think, wake it back up!
        if (status == 'done' && isListening && !isPaused) {
          _startListeningLoop(updateUI);
        }
      },
    );

    if (available) {
      isListening = true;
      isPaused = false;
      _finalTranscript = ""; // Reset memory for a new message
      _startListeningLoop(updateUI);
    }
  }

  void _startListeningLoop(Function updateUI) {
    _speechToText.listen(
      onResult: (result) {
        // Every time the engine thinks a sentence is "Final", we add it to memory
        if (result.finalResult) {
          _finalTranscript = '$_finalTranscript ${result.recognizedWords}'
              .trim();
        }

        // Display = History + whatever you are currently saying
        messageController.text = '$_finalTranscript ${result.recognizedWords}'
            .trim();

        // --- FIX: FORCE SCROLL TO BOTTOM ---
        // This ensures you always see the last word on the 2nd line
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

  // --- FIX: CLEAR TEXT AFTER SEND ---
  void stopRecordingCompletely() {
    isListening = false;
    isPaused = false;
    _finalTranscript = ""; // Wipe the memory
    _speechToText.stop();
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
    if (isListening) {
      stopRecordingCompletely(); // We will create this function next
      updateUI(); // Refresh icons to show gray mic
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

    // Save user message to database
    await dbService.saveMessage(
      currentChatId!,
      Message(text: msgText, isUser: true),
    );
    messageController.clear();
    isTyping = true;
    updateUI();

    // --- THE AI MEMORY FIX ---

    // 1. Get user profile (Age, Status, Interests, etc.)
    var userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(dbService.uid)
        .get();
    var u = userSnap.data() as Map<String, dynamic>;

    // 2. Create the "Context Instruction"
    String contextPrompt =
        "You are NEXA, a helpful assistant. "
        "User Profile: ${u['status']} aged ${u['age']} from ${u['country']}. "
        "Interests: ${u['interests']}. Goals: ${u['goals']}. "
        "Always answer in a way that matches this background.";

    // 3. Get chat history
    var messageDocs = await dbService.getMessagesOnce(currentChatId!);
    List<Message> history = messageDocs
        .map((doc) => Message(text: doc['text'], isUser: doc['isUser']))
        .toList();

    // 4. Prepend the memory instruction so the AI reads it first
    List<Message> fullContext = [
      Message(text: contextPrompt, isUser: false),
      ...history,
    ];

    // 5. Send everything to AI
    String response = await apiService.sendMessage(fullContext);

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
