import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'player_service.dart';

late MusikiAudioHandler audioHandler;

class MusikiAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  MusikiAudioHandler() {
    // 1. Broadcast state on native events (buffering, position, etc.)
    _player.playbackEventStream.listen(_broadcastState);

    // 2. Broadcast state whenever playing/pause or processingState changes
    _player.playerStateStream.listen((state) {
      _broadcastState();

      // AUTO-ADVANCE: When track completes, play the next song in queue
      if (state.processingState == ProcessingState.completed) {
        if (_player.loopMode != LoopMode.one) {
          skipToNext();
        }
      }
    });
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  void setLoopMode(LoopMode mode) => _player.setLoopMode(mode);
  void setShuffleModeEnabled(bool enabled) => _player.setShuffleModeEnabled(enabled);

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    try {
      final audioSource = AudioSource.uri(
        Uri.parse(mediaItem.id),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
          'Accept': '*/*',
          'Connection': 'keep-alive',
          'Icy-MetaData': '1',
        },
      );
      await _player.setAudioSource(audioSource);
      _player.play();
    } catch (e) {
      print("Audio Stream Error: $e");
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  // CONNECT SYSTEM NOTIFICATION & LOCK-SCREEN BUTTONS TO QUEUE
  @override
  Future<void> skipToNext() => PlayerService().skipNext();

  @override
  Future<void> skipToPrevious() => PlayerService().skipPrevious();

  // BROADCAST CURRENT REAL-TIME STATE TO ANDROID SYSTEM
  void _broadcastState([PlaybackEvent? event]) {
    final playing = _player.playing;
    final processingState = _player.processingState;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          // Correctly toggles Pause when playing, Play when paused
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[processingState] ?? AudioProcessingState.idle,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event?.currentIndex,
      ),
    );
  }

  // Cues a restored song at the saved timestamp without auto-playing
  Future<void> prepareMediaItem(MediaItem item, Duration initialPosition) async {
    mediaItem.add(item);
    try {
      final audioSource = AudioSource.uri(
        Uri.parse(item.id),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
          'Accept': '*/*',
          'Connection': 'keep-alive',
          'Icy-MetaData': '1',
        },
      );
      // Prepares the stream at the saved timestamp while keeping playback paused
      await _player.setAudioSource(audioSource, initialPosition: initialPosition);
      _broadcastState();
    } catch (e) {
      print("Prepare Media Item Error: $e");
    }
  }
}
