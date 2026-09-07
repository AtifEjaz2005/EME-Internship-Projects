import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/mini_player_color.dart';
import 'audio_handler.dart';
import '../models/music_track.dart';
import 'audius_provider.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  // State Notifiers
  ValueNotifier<String?> currentSongId = ValueNotifier(null);
  ValueNotifier<String?> currentSongTitle = ValueNotifier(null);
  ValueNotifier<String?> currentArtist = ValueNotifier(null);
  ValueNotifier<String?> currentImageUrl = ValueNotifier(null);
  ValueNotifier<Color> miniPlayerBgColor = ValueNotifier(
    const Color(0xFF222326),
  );

  ValueNotifier<bool> isShuffle = ValueNotifier(false);
  ValueNotifier<LoopMode> loopMode = ValueNotifier(LoopMode.off);

  Stream<Duration> get positionStream => audioHandler.positionStream;
  Stream<Duration?> get durationStream => audioHandler.durationStream;
  Stream<PlaybackState> get playbackStateStream => audioHandler.playbackState.stream;

  Future<void> playSong(
    String id,
    String url,
    String title,
    String artist,
    String image,
  ) async {
    currentSongId.value = id;
    currentSongTitle.value = title;
    currentArtist.value = artist;
    currentImageUrl.value = image;
    miniPlayerBgColor.value = MiniPlayerColor.getNewColor();

    try {
      await audioHandler.playMediaItem(
        MediaItem(
          id: url,
          album: "MUSIKI Mixtape",
          title: title,
          artist: artist,
          artUri: Uri.parse(image),
        ),
      );
      // Wait for state update
      await Future.delayed(const Duration(milliseconds: 200));
      audioHandler.play();
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  void togglePlay() {
    if (audioHandler.playbackState.value.playing) {
      audioHandler.pause();
    } else {
      audioHandler.play();
    }
  }

  void seek(Duration position) {
    audioHandler.seek(position);
  }

  void toggleRepeat() {
    LoopMode newMode = (loopMode.value == LoopMode.off)
        ? LoopMode.one
        : LoopMode.off;
    loopMode.value = newMode;
    audioHandler.setLoopMode(newMode);
  }

  void toggleShuffle() {
    isShuffle.value = !isShuffle.value;
    audioHandler.setShuffleModeEnabled(isShuffle.value);
  }

  void skipNext() => audioHandler.skipToNext();
  void skipPrevious() => audioHandler.skipToPrevious();

  void dispose() {
    audioHandler.stop();
  }

  Future<void> playTrack(MusicTrack track) async {
    // 1. Update UI Metadata immediately
    currentSongId.value = track.id;
    currentSongTitle.value = track.title;
    currentArtist.value = track.artist;
    currentImageUrl.value = track.artworkUrl; // FIX: Ensure this is updated for the MiniPlayer
    miniPlayerBgColor.value = MiniPlayerColor.getNewColor();

    try {
      String? streamUrl = await AudiusProvider().resolvePlayback(track);
      if (streamUrl != null) {
        await audioHandler.playMediaItem(
          MediaItem(
            id: streamUrl,
            album: "Audius",
            title: track.title,
            artist: track.artist,
            artUri: Uri.parse(track.artworkUrl),
          ),
        );
        // The audioHandler automatically updates its playbackState to 'playing'
      }
    } catch (e) {
      debugPrint("Playback Error: $e");
    }
  }
}
