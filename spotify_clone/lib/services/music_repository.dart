import '../models/music_track.dart';
import 'saavn_provider.dart';
import 'audius_provider.dart';
import 'soundcloud_provider.dart'; // ADDED

class MusicRepository {
  static final SaavnProvider _saavn = SaavnProvider();
  static final SoundCloudProvider _soundCloud = SoundCloudProvider(); // ADDED
  static final AudiusProvider _audius = AudiusProvider();

  // Search all providers in parallel
  static Future<List<MusicTrack>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final results = await Future.wait([
        _saavn.search(cleanQuery),       // 1. Saavn: Mainstream Punjabi, Bollywood, Pop
        _soundCloud.search(cleanQuery),  // 2. SoundCloud: Persian, Iranian, Global, Rap
        _audius.search(cleanQuery),      // 3. Audius: Indie, Electronic, Remixes
      ]);

      final saavnTracks = results[0];
      final soundCloudTracks = results[1];
      final audiusTracks = results[2];

      // Merge: Saavn + SoundCloud first for maximum relevance, then Audius
      return [
        ...saavnTracks,
        ...soundCloudTracks,
        ...audiusTracks,
      ];
    } catch (e) {
      return [];
    }
  }

  // Resolve the actual playback stream regardless of which provider it came from
  static Future<String?> resolvePlayback(MusicTrack track) async {
    if (track.provider == 'saavn') {
      return await _saavn.resolvePlayback(track);
    } else if (track.provider == 'soundcloud') {
      return await _soundCloud.resolvePlayback(track); // ADDED
    } else if (track.provider == 'audius') {
      return await _audius.resolvePlayback(track);
    }
    return track.audioUrl;
  }
}
