import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlayerService {
  // Singleton pattern so the whole app uses the same player
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  // Notifiers to update UI automatically
  ValueNotifier<bool> isPlaying = ValueNotifier(false);
  ValueNotifier<String?> currentSongTitle = ValueNotifier(null);
  ValueNotifier<String?> currentArtist = ValueNotifier(null);

  Future<void> playSong(String url, String title, String artist) async {
    try {
      currentSongTitle.value = title;
      currentArtist.value = artist;
      await _player.setUrl(url);
      _player.play();
      isPlaying.value = true;
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  void togglePlay() {
    if (_player.playing) {
      _player.pause();
      isPlaying.value = false;
    } else {
      _player.play();
      isPlaying.value = true;
    }
  }
}
