import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  final String apiKey =
      "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";

  http.Client? _client;

  Future<String> sendMessage(List<Message> messages) async {
    _client = http.Client();

    final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    try {
      final response = await _client!.post(
        url,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "http://localhost:3000",
          "X-Title": "NEXA AI Chatbot",
        },
        body: jsonEncode({
          // 3. Using a high-quality FREE model to avoid credit issues
          "model": "nvidia/nemotron-3-ultra-550b-a55b:free",

          // 4. Converting messages back to User/Assistant format
          "messages": messages.map((m) => m.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // 5. Finding the AI text in the OpenRouter box
        return data["choices"][0]["message"]["content"];
      } else if (response.statusCode == 402) {
        return "Error: Out of credits. Please switch to a free model on OpenRouter.";
      } else {
        // Prints the real error in the VS Code terminal for you to see
        print("OPENROUTER ERROR: ${response.body}");
        return "Sorry, I couldn't connect to the brain.";
      }
    } catch (e) {
      // Happens when you click "Stop"
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
