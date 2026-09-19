import 'dart:convert';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/mini_player_color.dart';
import '../models/music_track.dart';
import 'audius_provider.dart';
import 'audio_handler.dart';
import 'music_repository.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal() {
    _initPositionSaver();
  }

  // State Notifiers
  ValueNotifier<String?> currentSongId = ValueNotifier(null);
  ValueNotifier<String?> currentSongTitle = ValueNotifier(null);
  ValueNotifier<String?> currentArtist = ValueNotifier(null);
  ValueNotifier<String?> currentImageUrl = ValueNotifier(null);
  ValueNotifier<Color> miniPlayerBgColor = ValueNotifier(const Color(0xFF222326));
  ValueNotifier<MusicTrack?> currentTrack = ValueNotifier(null);

  ValueNotifier<bool> isShuffle = ValueNotifier(false);
  ValueNotifier<LoopMode> loopMode = ValueNotifier(LoopMode.off);

  // Queue State
  List<MusicTrack> currentQueue = [];
  int currentQueueIndex = 0;

  // Streams directly from audioHandler
  Stream<Duration> get positionStream => audioHandler.positionStream;
  Stream<Duration?> get durationStream => audioHandler.durationStream;
  Stream<PlaybackState> get playbackStateStream => audioHandler.playbackState.stream;

  // Throttled position saving to local storage
  int _lastSavedSecond = 0;
  void _initPositionSaver() {
    positionStream.listen((pos) {
      if ((pos.inSeconds - _lastSavedSecond).abs() >= 2) {
        _lastSavedSecond = pos.inSeconds;
        _savePosition(pos.inSeconds);
      }
    });
  }

  Future<void> _saveSession(MusicTrack track) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_saved_track', jsonEncode(track.toMap()));
    } catch (e) {
      debugPrint("Save session error: $e");
    }
  }

  Future<void> _savePosition(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_saved_position', seconds);
    } catch (e) {
      debugPrint("Save position error: $e");
    }
  }

  // RESTORE SESSION ON APP LAUNCH
  Future<void> restoreLastSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackString = prefs.getString('last_saved_track');
      final savedSeconds = prefs.getInt('last_saved_position') ?? 0;

      if (trackString != null) {
        final Map<String, dynamic> trackMap = jsonDecode(trackString);
        final track = MusicTrack.fromMap(trackMap);

        currentTrack.value = track;
        currentSongId.value = track.id;
        currentSongTitle.value = track.title;
        currentArtist.value = track.artist;
        currentImageUrl.value = track.artworkUrl;
        currentQueue = [track];
        currentQueueIndex = 0;

        // Resolve stream link and cue in audioHandler paused at saved second
        String? streamUrl;
        if (track.provider == 'audius') {
          streamUrl = await AudiusProvider().resolvePlayback(track);
        } else {
          streamUrl = track.audioUrl;
        }

        if (streamUrl != null) {
          await audioHandler.prepareMediaItem(
            MediaItem(
              id: streamUrl,
              album: "MUSIKI",
              title: track.title,
              artist: track.artist,
              artUri: Uri.parse(track.artworkUrl),
            ),
            Duration(seconds: savedSeconds),
          );
        }
      }
    } catch (e) {
      debugPrint("Restore session error: $e");
    }
  }

  // PLAY FROM QUEUE
  Future<void> playTrackFromQueue(List<MusicTrack> queue, int index) async {
    if (queue.isEmpty || index < 0 || index >= queue.length) return;
    currentQueue = List.from(queue);
    currentQueueIndex = index;
    await playTrack(currentQueue[currentQueueIndex]);
  }

  // PLAY SINGLE TRACK
  Future<void> playTrack(MusicTrack track) async {
    currentTrack.value = track;
    currentSongId.value = track.id;
    currentSongTitle.value = track.title;
    currentArtist.value = track.artist;
    currentImageUrl.value = track.artworkUrl;
    miniPlayerBgColor.value = MiniPlayerColor.getNewColor();

    // Persist this track immediately
    _saveSession(track);

    if (currentQueue.isEmpty || !currentQueue.contains(track)) {
      currentQueue = [track];
      currentQueueIndex = 0;
    } else {
      currentQueueIndex = currentQueue.indexOf(track);
    }

    try {
      String? streamUrl = await MusicRepository.resolvePlayback(track);

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

  void togglePlay() async {
    if (audioHandler.playbackState.value.playing) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }

  void seek(Duration position) {
    audioHandler.seek(position);
    _savePosition(position.inSeconds);
  }

  void toggleRepeat() {
    LoopMode newMode = (loopMode.value == LoopMode.off) ? LoopMode.one : LoopMode.off;
    loopMode.value = newMode;
    audioHandler.setLoopMode(newMode);
  }

  void toggleShuffle() {
    isShuffle.value = !isShuffle.value;
    audioHandler.setShuffleModeEnabled(isShuffle.value);
  }

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
