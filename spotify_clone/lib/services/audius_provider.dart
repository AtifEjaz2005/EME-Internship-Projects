import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/music_track.dart';
import 'music_provider.dart';

class AudiusProvider implements MusicProvider {
  // Audius requires an app name for tracking (Official requirement)
  final String _appName = "MUSIKI_APP_2026";
  String? _baseNode;

  // 1. Find an active Audius server (Discovery Node)
  Future<void> _initNode() async {
    if (_baseNode != null) return;
    try {
      final response = await http.get(Uri.parse("https://api.audius.co"));
      if (response.statusCode == 200) {
        // Redirection logic or direct host fetch
        _baseNode = response.body.trim();
        // Fallback if the above isn't a direct string:
        _baseNode = "https://discoveryprovider.audius.co";
      }
    } catch (e) {
      _baseNode = "https://discoveryprovider.audius.co"; // Default fallback
    }
  }

  @override
  Future<List<MusicTrack>> search(String query) async {
    await _initNode();
    if (query.isEmpty) return [];

    final url = "$_baseNode/v1/tracks/search?query=$query&app_name=$_appName";

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        return data.map((json) => MusicTrack(
          id: json['id'],
          title: json['title'],
          artist: json['user']['name'],
          artworkUrl: json['artwork']?['150x150'] ?? "",
          provider: 'audius',
          providerTrackId: json['id'],
          duration: Duration(seconds: json['duration'] ?? 0),
        )).toList();
      }
      return [];
    } catch (e) {
      print("Audius Search Error: $e");
      return [];
    }
  }

  @override
  Future<String?> resolvePlayback(MusicTrack track) async {
    await _initNode();
    // Official Streaming Endpoint: /v1/tracks/{track_id}/stream
    // This returns a direct audio redirect
    return "$_baseNode/v1/tracks/${track.providerTrackId}/stream?app_name=$_appName";
  }
}
