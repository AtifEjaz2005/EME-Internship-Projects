import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceAssistant {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool isListening = false;
  bool isPaused = false;
  String? currentlySpeakingText;
  String _savedWords = "";

  void toggleVoice(TextEditingController controller, Function updateUI) async {
    // 1. MANUAL PAUSE
    if (isListening && !isPaused) {
      isPaused = true;
      _savedWords = controller.text;
      await _speechToText.stop();
      updateUI();
      return;
    }

    // 2. RESUME
    if (isPaused) {
      isPaused = false;
      _startMic(controller, updateUI);
      return;
    }

    // 3. START FRESH
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        // Auto-restart if it stops because of silence but we haven't hit 'Send'
        if (status == 'done' && isListening && !isPaused) {
          _savedWords = controller.text;
          _startMic(controller, updateUI);
        }
      },
    );

    if (available) {
      isListening = true;
      isPaused = false;
      _savedWords = "";
      _startMic(controller, updateUI);
    }
  }

  void _startMic(TextEditingController controller, Function updateUI) {
    _speechToText.listen(
      onResult: (result) {
        controller.text = '$_savedWords ${result.recognizedWords}'.trim();
        // Force scroll to end of input box
        controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
        updateUI();
      },
      listenOptions: SpeechListenOptions(partialResults: true, listenMode: ListenMode.dictation),
    );
    updateUI();
  }

  // STOP EVERYTHING (Mic and internal memory)
  void reset() {
    isListening = false;
    isPaused = false;
    _savedWords = "";
    _speechToText.stop();
  }

  // READ ALOUD TOGGLE
  Future<void> toggleReadAloud(String text, Function updateUI) async {
    if (currentlySpeakingText == text) {
      await _tts.stop();
      currentlySpeakingText = null;
    } else {
      await _tts.stop();
      currentlySpeakingText = text;
      updateUI();
      await _tts.speak(text);
      _tts.setCompletionHandler(() { currentlySpeakingText = null; updateUI(); });
    }
    updateUI();
  }
}
