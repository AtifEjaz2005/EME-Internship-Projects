import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  final String apiKey = "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";

  http.Client? _client;

  Stream<String> sendMessageStream(List<Message> messages) async* {
    _client = http.Client();
    final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    try {
      // 2. Create the Request
      final request = http.Request("POST", url);

      // 3. THE FIX: Explicitly set the headers
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.headers['Content-Type'] = 'application/json';
      request.headers['HTTP-Referer'] = 'http://localhost:3000';
      request.headers['X-Title'] = 'NEXA AI';

      // 4. Set the Body
      request.body = jsonEncode({
        "model": "nvidia/nemotron-3-ultra-550b-a55b:free",
        "messages": messages.map((m) => m.toJson()).toList(),
        "stream": true,
      });

      // 5. Send the Request
      final response = await _client!.send(request);

      // 6. If it fails, log the specific error
      if (response.statusCode != 200) {
        final errorMsg = await response.stream.bytesToString();
        print("OPENROUTER ERROR: $errorMsg"); // Check VS Code terminal
        yield "Error: ${response.statusCode}. Check API Key.";
        return;
      }

      // 7. Process the stream of words
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        if (_client == null) break;
        final lines = chunk.split("\n");
        for (var line in lines) {
          if (line.startsWith("data: ")) {
            final dataText = line.substring(6).trim();
            if (dataText == "[DONE]") return;
            try {
              final json = jsonDecode(dataText);
              yield json["choices"][0]["delta"]["content"] ?? "";
            } catch (e) {
              continue;
            }
          }
        }
      }
    } catch (e) {
      print("Connection Error: $e");
      yield "Connection lost.";
    }
  }

  void stopResponse() {
    _client?.close();
    _client = null;
  }
}

// atifejaz436@gmail.com
// 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
// nvidia/nemotron-3-ultra-550b-a55b:free


// atifatwork31@gmail.com
// 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
