import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/mini_player_color.dart';
import '../models/music_track.dart';
import 'audius_provider.dart';
import 'audio_handler.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  // State Notifiers
  ValueNotifier<String?> currentSongId = ValueNotifier(null);
  ValueNotifier<String?> currentSongTitle = ValueNotifier(null);
  ValueNotifier<String?> currentArtist = ValueNotifier(null);
  ValueNotifier<String?> currentImageUrl = ValueNotifier(null);
  ValueNotifier<Color> miniPlayerBgColor = ValueNotifier(const Color(0xFF222326));
  ValueNotifier<MusicTrack?> currentTrack = ValueNotifier(null);

  ValueNotifier<bool> isShuffle = ValueNotifier(false);
  ValueNotifier<LoopMode> loopMode = ValueNotifier(LoopMode.off);

  // QUEUE STATE
  List<MusicTrack> currentQueue = [];
  int currentQueueIndex = 0;

  // Streams directly from audioHandler
  Stream<Duration> get positionStream => audioHandler.positionStream;
  Stream<Duration?> get durationStream => audioHandler.durationStream;
  Stream<PlaybackState> get playbackStateStream => audioHandler.playbackState.stream;

  // 1. PLAY FROM A QUEUE (Search results or Playlist)
  Future<void> playTrackFromQueue(List<MusicTrack> queue, int index) async {
    if (queue.isEmpty || index < 0 || index >= queue.length) return;
    currentQueue = List.from(queue);
    currentQueueIndex = index;
    await playTrack(currentQueue[currentQueueIndex]);
  }

  // 2. PLAY SINGLE TRACK
  Future<void> playTrack(MusicTrack track) async {
    currentTrack.value = track;
    currentSongId.value = track.id;
    currentSongTitle.value = track.title;
    currentArtist.value = track.artist;
    currentImageUrl.value = track.artworkUrl;
    miniPlayerBgColor.value = MiniPlayerColor.getNewColor();

    // Preserve the queue if this track is already in it
    if (currentQueue.isEmpty || !currentQueue.contains(track)) {
      currentQueue = [track];
      currentQueueIndex = 0;
    } else {
      currentQueueIndex = currentQueue.indexOf(track);
    }

    try {
      String? streamUrl;
      if (track.provider == 'audius') {
        streamUrl = await AudiusProvider().resolvePlayback(track);
      } else {
        streamUrl = track.audioUrl;
      }

      if (streamUrl != null) {
        await audioHandler.playMediaItem(
          MediaItem(
            id: streamUrl,
            album: "MUSIKI",
            title: track.title,
            artist: track.artist,
            artUri: Uri.parse(track.artworkUrl),
          ),
        );
      }
    } catch (e) {
      debugPrint("Playback Error: $e");
    }
  }

  // PLAY / PAUSE
  void togglePlay() async {
    if (audioHandler.playbackState.value.playing) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }

  void seek(Duration position) => audioHandler.seek(position);

  // REPEAT TOGGLE
  void toggleRepeat() {
    LoopMode newMode = (loopMode.value == LoopMode.off) ? LoopMode.one : LoopMode.off;
    loopMode.value = newMode;
    audioHandler.setLoopMode(newMode);
  }

  // SHUFFLE TOGGLE
  void toggleShuffle() {
    isShuffle.value = !isShuffle.value;
    audioHandler.setShuffleModeEnabled(isShuffle.value);
  }

  // 3. SKIP NEXT (With Shuffle & Loop logic)
  Future<void> skipNext() async {
    if (currentQueue.isEmpty) return;

    if (isShuffle.value && currentQueue.length > 1) {
      int nextIndex;
      do {
        nextIndex = Random().nextInt(currentQueue.length);
      } while (nextIndex == currentQueueIndex && currentQueue.length > 1);
      currentQueueIndex = nextIndex;
    } else {
      if (currentQueueIndex < currentQueue.length - 1) {
        currentQueueIndex++;
      } else {
        if (loopMode.value == LoopMode.all) {
          currentQueueIndex = 0;
        } else {
          return;
        }
      }
    }

    await playTrack(currentQueue[currentQueueIndex]);
  }

  // 4. SKIP PREVIOUS (Spotify style: resets track if played > 3s, otherwise goes to prev track)
  Future<void> skipPrevious() async {
    if (currentQueue.isEmpty) return;

    final currentPosition = audioHandler.playbackState.value.position;
    if (currentPosition.inSeconds > 3) {
      seek(Duration.zero);
    } else if (currentQueueIndex > 0) {
      currentQueueIndex--;
      await playTrack(currentQueue[currentQueueIndex]);
    } else {
      seek(Duration.zero);
    }
  }

  void dispose() {
    audioHandler.stop();
  }
}
