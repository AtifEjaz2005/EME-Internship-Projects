import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceAssistant {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool isListening = false;
  bool isPaused = false;
  String? currentlySpeakingText;

  // This acts as a "Storage Box" for your words so they don't get deleted
  String _savedWords = "";

  // 1. THE MAIN TOGGLE (Listen / Pause / Resume)
  void toggleVoice(TextEditingController controller, Function updateUI) async {
    // If currently recording -> PAUSE IT
    if (isListening && !isPaused) {
      isPaused = true;
      _savedWords = controller.text; // Save what we have so far
      await _speechToText.stop();
      updateUI();
      return;
    }

    // If currently paused -> RESUME IT
    if (isPaused) {
      isPaused = false;
      _startMic(controller, updateUI);
      return;
    }

    // START FRESH
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' && isListening && !isPaused) {
          _savedWords = controller.text; // Save current text
          _startMic(controller, updateUI); // Wake it back up immediately!
        }
      },
    );

    if (available) {
      isListening = true;
      isPaused = false;
      _savedWords = "";
      controller.clear();
      _startMic(controller, updateUI);
    }
  }

  // 2. THE ACTUAL MIC LOGIC
  void _startMic(TextEditingController controller, Function updateUI) {
    _speechToText.listen(
      onResult: (result) {
        // Combine previously saved words with the new words being heard
        String currentWords = result.recognizedWords;
        controller.text = ("$_savedWords $currentWords").trim();

        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );

        updateUI();
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
    updateUI();
  }

  // 3. THE RESET (Call this when Send is clicked)
  void reset() {
    isListening = false;
    isPaused = false;
    _savedWords = "";
    _speechToText.stop();
  }

  // 4. READ ALOUD LOGIC
  Future<void> toggleReadAloud(String text, Function updateUI) async {

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
}
