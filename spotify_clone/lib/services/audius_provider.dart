import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/music_track.dart';
import 'music_provider.dart';

class AudiusProvider implements MusicProvider {
  final String _appName = "MUSIKI_APP_2026";

  // STATIC CACHE: Discovered once, reused across all searches
  static String? _cachedNode;

  Future<String> _getNode() async {
    if (_cachedNode != null) return _cachedNode!;

    try {
      // api.audius.co returns a list of healthy discovery nodes
      final response = await http
          .get(Uri.parse("https://api.audius.co"))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List nodes = body['data'] ?? [];
        if (nodes.isNotEmpty) {
          _cachedNode = nodes.first.toString();
          return _cachedNode!;
        }
      }
    } catch (e) {
      debugPrint("Discovery node fetch failed, using fallback: $e");
    }

    // Fast, reliable default fallback node
    _cachedNode = "https://discoveryprovider.audius.co";
    return _cachedNode!;
  }

  Future<List<MusicTrack>> getTrendingTracks({String? genre, int limit = 10}) async {
    final node = await _getNode();

    // Build trending URL with optional genre filter
    String url = "$node/v1/tracks/trending?app_name=$_appName&limit=$limit";
    if (genre != null && genre.isNotEmpty) {
      url += "&genre=${Uri.encodeComponent(genre)}";
    }

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['data'] ?? [];

        return data.map((json) => MusicTrack(
          id: json['id']?.toString() ?? '',
          title: json['title'] ?? 'Unknown Track',
          artist: json['user']?['name'] ?? 'Unknown Artist',
          artworkUrl: json['artwork']?['480x480'] ?? json['artwork']?['150x150'] ?? '',
          provider: 'audius',
          providerTrackId: json['id']?.toString() ?? '',
          duration: Duration(seconds: json['duration'] ?? 0),
        )).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Audius Trending Error: $e");
      return [];
    }
  }

  @override
  Future<List<MusicTrack>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final node = await _getNode();
    // limit=15 makes network payload 5x smaller and faster
    final url = "$node/v1/tracks/search?query=${Uri.encodeComponent(cleanQuery)}&app_name=$_appName&limit=15";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['data'] ?? [];

        return data.map((json) => MusicTrack(
          id: json['id']?.toString() ?? '',
          title: json['title'] ?? 'Unknown Track',
          artist: json['user']?['name'] ?? 'Unknown Artist',
          artworkUrl: json['artwork']?['150x150'] ?? '',
          provider: 'audius',
          providerTrackId: json['id']?.toString() ?? '',
          duration: Duration(seconds: json['duration'] ?? 0),
        )).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Audius Search Error: $e");
      return [];
    }
  }

  @override
  Future<String?> resolvePlayback(MusicTrack track) async {
    final node = await _getNode();
    return "$node/v1/tracks/${track.providerTrackId}/stream?app_name=$_appName";
  }
}
