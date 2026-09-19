import '../models/music_track.dart';
import 'saavn_provider.dart';
import 'audius_provider.dart';

class MusicRepository {
  static final SaavnProvider _saavn = SaavnProvider();
  static final AudiusProvider _audius = AudiusProvider();

  // Search both libraries in parallel
  static Future<List<MusicTrack>> search(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final results = await Future.wait([
        _saavn.search(query),  // Mainstream hits (Punjabi, Bollywood, Global Pop)
        _audius.search(query), // Indie, EDM, Remixes
      ]);

      final saavnTracks = results[0];
      final audiusTracks = results[1];

      // Saavn tracks come first (higher relevance for mainstream titles), followed by Audius
      return [...saavnTracks, ...audiusTracks];
    } catch (e) {
      return [];
    }
  }

  // Resolve the actual playback stream regardless of which provider it came from
  static Future<String?> resolvePlayback(MusicTrack track) async {
    if (track.provider == 'saavn') {
      return await _saavn.resolvePlayback(track);
    } else if (track.provider == 'audius') {
      return await _audius.resolvePlayback(track);
    }
    return track.audioUrl;
  }
}
