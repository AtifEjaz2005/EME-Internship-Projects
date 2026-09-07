import '../models/music_track.dart';

abstract class MusicProvider {
  // Search for songs based on a query
  Future<List<MusicTrack>> search(String query);

  // Get the actual playable streaming URL
  Future<String?> resolvePlayback(MusicTrack track);
}
