import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // TODO: Kendi OpenAI/Gemini API anahtarını buraya veya env değişkenine koy.
  final String _apiKey = 'YOUR_OPENAI_API_KEY';
  final String _endpoint = 'https://api.openai.com/v1/chat/completions';

  Future<String> askAssistant(String prompt) async {
    final body = {
      "model": "gpt-4o-mini", // placeholder; servis ve model isteğe bağlı
      "messages": [
        {"role": "system", "content": "You are Finora assistant: concise, helpful, friendly."},
        {"role": "user", "content": prompt},
      ],
      "max_tokens": 300,
      "temperature": 0.7
    };

    final res = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      final text = j['choices'][0]['message']['content'];
      return text ?? 'Üzgünüm, cevap alınamadı.';
    } else {
      return 'AI servisine erişilemiyor: ${res.statusCode}';
    }
  }
}
