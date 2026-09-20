import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LyricsLine {
  final Duration timestamp;
  final String text;

  LyricsLine({required this.timestamp, required this.text});
}

class LyricsService {
  static final LyricsService _instance = LyricsService._internal();
  factory LyricsService() => _instance;
  LyricsService._internal();

  // Clean artist & title strings (remove "(Official Video)", "feat.", etc.)
  String _cleanString(String text) {
    return text
        .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
        .replaceAll(RegExp(r'ft\..*|feat\..*', caseSensitive: false), '')
        .trim();
  }

  Future<Map<String, dynamic>?> fetchLyrics({
    required String trackName,
    required String artistName,
    int? durationSeconds,
  }) async {
    final cleanTitle = _cleanString(trackName);
    final cleanArtist = _cleanString(artistName);

    // LRCLIB API endpoint (Completely free, no key required)
    String url = "https://lrclib.net/api/get?track_name=${Uri.encodeComponent(cleanTitle)}&artist_name=${Uri.encodeComponent(cleanArtist)}";
    if (durationSeconds != null && durationSeconds > 0) {
      url += "&duration=$durationSeconds";
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Musiki-Music-App/1.0.0 (https://github.com)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String? syncedLyrics = data['syncedLyrics'];
        final String? plainLyrics = data['plainLyrics'];

        return {
          'synced': syncedLyrics != null ? _parseLrc(syncedLyrics) : null,
          'plain': plainLyrics,
        };
      }
    } catch (e) {
      debugPrint("Lyrics fetch error: $e");
    }
    return null;
  }

  // Parses standard [mm:ss.xx] LRC formatted strings into timestamps
  List<LyricsLine> _parseLrc(String lrcContent) {
    final List<LyricsLine> lines = [];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.?(\d{2,3})?\](.*)');

    for (final line in lrcContent.split('\n')) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millis = match.group(3) != null
            ? int.parse(match.group(3)!.padRight(3, '0').substring(0, 3))
            : 0;
        final text = match.group(4)?.trim() ?? '';

        if (text.isNotEmpty) {
          lines.add(
            LyricsLine(
              timestamp: Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
              text: text,
            ),
          );
        }
      }
    }
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }
}
