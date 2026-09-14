import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'player_service.dart';

late MusikiAudioHandler audioHandler;

class MusikiAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  MusikiAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // AUTO-PLAY NEXT: Listen for song completion
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Only skip to next if not repeating the same song
        if (_player.loopMode != LoopMode.one) {
          PlayerService().skipNext();
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
  Future<void> stop() => _player.stop();

  // CONNECT LOCK-SCREEN / HEADPHONE BUTTONS TO QUEUE
  @override
  Future<void> skipToNext() => PlayerService().skipNext();
  @override
  Future<void> skipToPrevious() => PlayerService().skipPrevious();

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
