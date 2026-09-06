import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class YouTubeService {
  // REPLACE THIS with your actual API Key
  final String apiKey = dotenv.env['apiKey'] ?? "";

  Future<List<Map<String, dynamic>>> searchSongs(String query) async {
    // We add "music" and "audio" to the query to ensure we get songs, not random vlogs
    final String url =
      "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=20&q=$query%20audio&type=video&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> songs = [];

        for (var item in data['items']) {
          songs.add({
            'id': item['id']['videoId'], // This is the unique Video ID
            'title': item['snippet']['title'],
            'artist': item['snippet']['channelTitle'],
            'imageUrl': item['snippet']['thumbnails']['high']['url'],
          });
        }
        return songs;
      } else {
        print("YouTube API Error: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching from YouTube: $e");
      return [];
    }
  }
}
