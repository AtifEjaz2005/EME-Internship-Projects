import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

// The global instance must be of type MusikiAudioHandler to see custom getters
late MusikiAudioHandler audioHandler;

class MusikiAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  MusikiAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  // EXPOSE THE STREAMS
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  // EXPOSE PLAYBACK CONTROLS
  void setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  // Renamed to avoid conflict with AudioService's built-in setShuffleMode
  void setShuffleModeEnabled(bool enabled) => _player.setShuffleModeEnabled(enabled);

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(mediaItem.id)));
      _player.play();
    } catch (e) {
      print("Audio Error: $e");
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
