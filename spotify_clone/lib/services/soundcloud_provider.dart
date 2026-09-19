import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/music_track.dart';
import 'music_provider.dart';

class SoundCloudProvider implements MusicProvider {
  // Cached dynamically discovered client ID
  static String? _cachedClientId;

  // 1. DYNAMIC AUTO-DISCOVERY: Extracts live client_id from soundcloud.com
  Future<String?> _getClientId() async {
    if (_cachedClientId != null && _cachedClientId!.isNotEmpty) {
      return _cachedClientId;
    }

    try {
      debugPrint("SoundCloud: Discovering live client ID from web assets...");
      final homeResponse = await http.get(
        Uri.parse("https://soundcloud.com"),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 6));

      if (homeResponse.statusCode == 200) {
        // Find script tags containing assets on soundcloud.com
        final scriptRegex = RegExp(r'<script[^>]+src="(https://a-v2\.sndcdn\.com/assets/[^"]+\.js)"');
        final matches = scriptRegex.allMatches(homeResponse.body);
        final scriptUrls = matches.map((m) => m.group(1)!).toList();

        // The client_id is embedded inside one of the main app bundles
        for (final scriptUrl in scriptUrls.reversed.take(5)) {
          try {
            final jsResponse = await http
                .get(Uri.parse(scriptUrl))
                .timeout(const Duration(seconds: 4));

            if (jsResponse.statusCode == 200) {
              final idMatch = RegExp(r'client_id[:=]"([a-zA-Z0-9]{32})"').firstMatch(jsResponse.body);
              if (idMatch != null) {
                _cachedClientId = idMatch.group(1);
                debugPrint("SoundCloud: Successfully found active client_id: $_cachedClientId");
                return _cachedClientId;
              }
            }
          } catch (_) {
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint("SoundCloud: Dynamic discovery error: $e");
    }

    // 2. FALLBACK: Verified live fallback IDs if dynamic scraping took too long
    final fallbacks = [
      "02gUJC0hH2ct1EGOcYXQIzRFU91c72Ea",
      "fDoItMDbsbZz8dY16ZzARCZmzgHBPotA",
      "2t9loNQH90kzJcsFCODdigxfp325aq4z",
    ];

    for (final fallback in fallbacks) {
      try {
        final testRes = await http
            .get(Uri.parse("https://api-v2.soundcloud.com/search/tracks?q=test&client_id=$fallback&limit=1"))
            .timeout(const Duration(seconds: 3));
        if (testRes.statusCode == 200) {
          _cachedClientId = fallback;
          debugPrint("SoundCloud: Using active fallback client_id: $fallback");
          return _cachedClientId;
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Future<List<MusicTrack>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final clientId = await _getClientId();
    if (clientId == null) {
      debugPrint("SoundCloud: No valid client ID available.");
      return [];
    }

    final url =
        "https://api-v2.soundcloud.com/search/tracks?q=${Uri.encodeComponent(cleanQuery)}&client_id=$clientId&limit=15";

    try {
      debugPrint("SoundCloud: Searching for '$cleanQuery'...");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List collection = data['collection'] ?? [];

        debugPrint("SoundCloud: Found ${collection.length} songs!");

        return collection.map((item) {
          final String trackId = item['id']?.toString() ?? '';

          // Replace default 100x100 with high-resolution 500x500 album art
          String art = item['artwork_url'] ?? item['user']?['avatar_url'] ?? '';
          if (art.contains('large.jpg')) {
            art = art.replaceAll('large.jpg', 't500x500.jpg');
          }

          return MusicTrack(
            id: trackId,
            title: item['title'] ?? 'Unknown Track',
            artist: item['user']?['username'] ?? 'SoundCloud Artist',
            artworkUrl: art,
            provider: 'soundcloud',
            providerTrackId: trackId,
            duration: Duration(milliseconds: item['duration'] ?? 0),
            audioUrl: null, // Resolved on tap
          );
        }).toList();
      } else {
        debugPrint("SoundCloud search returned HTTP ${response.statusCode}");
        // Invalidate expired client ID so it fetches a fresh one next time
        if (response.statusCode == 401) {
          _cachedClientId = null;
        }
      }
    } catch (e) {
      debugPrint("SoundCloud search exception: $e");
    }

    return [];
  }

  @override
  Future<String?> resolvePlayback(MusicTrack track) async {
    final clientId = await _getClientId();
    if (clientId == null) return null;

    final trackId = track.providerTrackId;

    try {
      // 1. Fetch track stream details
      final trackUrl = "https://api-v2.soundcloud.com/tracks/$trackId?client_id=$clientId";
      final response = await http.get(
        Uri.parse(trackUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> trackData = json.decode(response.body);
        final List transcodings = trackData['media']?['transcodings'] ?? [];

        // 2. Select progressive MP3 stream (native ExoPlayer compatibility)
        final selectedTranscoding = transcodings.firstWhere(
          (t) => (t['format']?['protocol'] ?? '') == 'progressive',
          orElse: () => transcodings.isNotEmpty ? transcodings.first : null,
        );

        if (selectedTranscoding != null && selectedTranscoding['url'] != null) {
          // 3. Resolve the authenticated direct CDN audio link
          final streamAuthUrl = "${selectedTranscoding['url']}?client_id=$clientId";
          final streamResponse = await http.get(
            Uri.parse(streamAuthUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            },
          ).timeout(const Duration(seconds: 5));

          if (streamResponse.statusCode == 200) {
            final streamData = json.decode(streamResponse.body);
            final String? streamUrl = streamData['url'];
            if (streamUrl != null && streamUrl.isNotEmpty) {
              debugPrint("SoundCloud: Stream URL resolved successfully!");
              return streamUrl;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("SoundCloud playback resolve error: $e");
    }

    return null;
  }
}
