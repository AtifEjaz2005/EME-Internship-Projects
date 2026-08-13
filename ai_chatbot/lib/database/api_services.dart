import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  final String apiKey = "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";
  http.Client? _client;

  Stream<String> sendMessageStream(List<Message> messages) async* {
    _client = http.Client();
    final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    final request = http.Request("POST", url);
    request.headers.addAll({
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    });

    request.body = jsonEncode({
      "model": "nvidia/nemotron-3-ultra-550b-a55b:free",
      "messages": messages.map((m) => m.toJson()).toList(),
      "stream": true,
    });

    try {
      final response = await _client!.send(request);
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split("\n");
        for (var line in lines) {
          if (line.startsWith("data: ")) {
            final data = line.substring(6);
            if (data.trim() == "[DONE]") break;
            try {
              final json = jsonDecode(data);
              yield json["choices"][0]["delta"]["content"] ?? "";
            } catch (e) { continue; }
          }
        }
      }
    } catch (e) {
      yield "Error connecting to brain.";
    }
  }

  void stopResponse() {
    _client?.close();
    _client = null;
  }
}



// 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
// nvidia/nemotron-3-ultra-550b-a55b:free
