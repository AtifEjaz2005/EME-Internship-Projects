import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  final String apiKey = "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";

  http.Client? _client;

  Future<String> sendMessage(List<Message> messages) async {

    _client = http.Client();
    var url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    try {
      var response = await _client!.post(
        url,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "deepseek/deepseek-chat",
          "messages": messages.map((m) => m.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } else {
        return "Sorry, I couldn't connect to the brain.";
      }
    } catch (e) {
      return "Message stopped.";
    }
  }

  void stopResponse() {
    if (_client != null) {
      _client!.close();
      _client = null;
    }
  }
}
