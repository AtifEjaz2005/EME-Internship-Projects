import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/music_track.dart';
import 'music_provider.dart';

class SaavnProvider implements MusicProvider {
  // Active mirrors so if one is blocked or down, the others take over
  static final List<String> _mirrors = [
    "https://jiosaavn-api2-eight.vercel.app/api",
    "https://saavn.sumit.co/api",
    "https://jiosaavn-api-lemon.vercel.app/api",
  ];

  @override
  Future<List<MusicTrack>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Try each mirror until one responds successfully
    for (String baseUrl in _mirrors) {
      final url = "$baseUrl/search/songs?query=${Uri.encodeComponent(cleanQuery)}&limit=15";

      try {
        debugPrint("Trying Saavn Mirror: $url");
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final Map<String, dynamic> body = json.decode(response.body);
          final List results = body['data']?['results'] ?? [];

          if (results.isNotEmpty) {
            debugPrint("Saavn successfully found ${results.length} songs!");

            return results.map((item) {
              // 1. High-res artwork
              final List images = item['image'] ?? [];
              String bestImage = '';
              if (images.isNotEmpty) {
                bestImage = images.last['url'] ?? images.last['link'] ?? '';
              }

              // 2. High-quality 320kbps / 160kbps stream link
              final List downloads = item['downloadUrl'] ?? [];
              String? bestAudio;
              if (downloads.isNotEmpty) {
                bestAudio = downloads.last['url'] ?? downloads.last['link'];
              }

              final durationSec = int.tryParse(item['duration']?.toString() ?? '0') ?? 0;

              return MusicTrack(
                id: item['id']?.toString() ?? '',
                title: item['name'] ?? item['title'] ?? 'Unknown Track',
                artist: item['primaryArtists'] ?? item['singers'] ?? 'Unknown Artist',
                artworkUrl: bestImage,
                provider: 'saavn',
                providerTrackId: item['id']?.toString() ?? '',
                duration: Duration(seconds: durationSec),
                audioUrl: bestAudio,
              );
            }).toList();
          }
        }
      } catch (e) {
        debugPrint("Mirror $baseUrl failed: $e, trying next mirror...");
        continue; // Try next mirror if this one fails
      }
    }

    debugPrint("All Saavn mirrors failed or timed out.");
    return [];
  }

  @override
  Future<String?> resolvePlayback(MusicTrack track) async {
    if (track.audioUrl != null && track.audioUrl!.isNotEmpty) {
      return track.audioUrl;
    }
    return null;
  }
}
