import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/mini_player_color.dart';
import 'audio_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  // State Notifiers
  ValueNotifier<bool> isPlaying = ValueNotifier(false);
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
      isPlaying.value = audioHandler.playbackState.value.playing;
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  void togglePlay() async {
    if (audioHandler.playbackState.value.playing) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
    isPlaying.value = audioHandler.playbackState.value.playing;
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

  Future<void> playYoutubeSong(
    String videoId,
    String title,
    String artist,
    String image,
  ) async {
    final yt = YoutubeExplode();

    try {
      currentSongTitle.value = title;
      currentArtist.value = artist;
      currentImageUrl.value = image;
      miniPlayerBgColor.value = MiniPlayerColor.getNewColor();

      debugPrint('Getting YouTube manifest for: $videoId');

      var manifest = await yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.mweb],
      );

      if (manifest.audioOnly.isEmpty) {
        throw Exception('No audio streams available');
      }

      final audioStream = manifest.audioOnly.withHighestBitrate();

      final audioUrl = audioStream.url.toString();

      debugPrint('========== YOUTUBE AUDIO ==========');
      debugPrint('Video ID: $videoId');
      debugPrint('Container: ${audioStream.container}');
      debugPrint('Codec: ${audioStream.audioCodec}');
      debugPrint('Bitrate: ${audioStream.bitrate}');
      debugPrint('URL: ${audioStream.url}');
      debugPrint('===================================');

      await audioHandler.playMediaItem(
        MediaItem(
          id: audioUrl,
          album: 'YouTube Music',
          title: title,
          artist: artist,
          artUri: Uri.parse(image),
        ),
      );

      isPlaying.value = true;
    } catch (e, stackTrace) {
      debugPrint('YouTube playback failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      yt.close();
    }
  }
}
