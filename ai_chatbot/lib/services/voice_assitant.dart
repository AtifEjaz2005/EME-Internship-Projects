import 'dart:async'; // Add this for the timer
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceAssistant {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool isListening = false;
  bool isPaused = false;
  String _savedWords = "";
  String? currentlySpeakingText;

  // --- TIMER LOGIC ---
  int _seconds = 0;
  Timer? _timer;
  String recordingTime = "0:00";

  void _startTimer(Function updateUI) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _seconds++;
      int mins = _seconds ~/ 60;
      int secs = _seconds % 60;
      recordingTime = "$mins:${secs.toString().padLeft(2, '0')}";
      updateUI();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _seconds = 0;
    recordingTime = "0:00";
  }

  // --- MIC LOGIC ---
  void toggleVoice(TextEditingController controller, Function updateUI) async {
    if (isListening && !isPaused) {
      isPaused = true;
      _savedWords = controller.text;
      await _speechToText.stop();
      _timer?.cancel(); // Pause the clock
      updateUI();
      return;
    }

    if (isPaused) {
      isPaused = false;
      _startMic(controller, updateUI);
      _startTimer(updateUI); // Resume the clock
      return;
    }

    bool available = await _speechToText.initialize();
    if (available) {
      isListening = true;
      isPaused = false;
      _savedWords = "";
      controller.clear();
      _startMic(controller, updateUI);
      _startTimer(updateUI); // Start clock
    }
  }

  void _startMic(TextEditingController controller, Function updateUI) {
    _speechToText.listen(
      onResult: (result) {
        controller.text = '$_savedWords ${result.recognizedWords}'.trim();
        controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
        updateUI();
      },
      listenOptions: SpeechListenOptions(partialResults: true, listenMode: ListenMode.dictation),
    );
  }

  void reset() {
    isListening = false;
    isPaused = false;
    _savedWords = "";
    _stopTimer();
    _speechToText.stop();
  }

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
