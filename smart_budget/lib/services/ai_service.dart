// lib/services/ai_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  late final GenerativeModel _model;

  // AIService Constructor'ı
  AIService() {
    // API anahtarını .env dosyasından okuma (main.dart'ta yüklenmişti)
    final apiKey = dotenv.env["GEMINI_API_KEY"];
    
    if (apiKey == null) {
      // API anahtarı yoksa uygulama başlatılırken hata fırlat
      throw Exception("GEMINI_API_KEY .env dosyasında bulunamadı.");
    }

    // PRD'ye uygun modeli başlatma (gemini-2.5-flash)
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Hızlı ve sohbet tabanlı görevler için
      apiKey: apiKey,
    );
  }

  // PRD R5.1.3: Kullanıcının doğal dil sorgularını işleyen temel metot
  Future<String> getResponse(String userQuery) async {
    try {
      final content = [Content.text(userQuery)];
      final response = await _model.generateContent(content);
      
      // Yanıtın sadece metin kısmını döndür
      return response.text ?? "I couldn't analyze your question. Please try again.";
    } catch (e) {
      print('AI Service Error: $e');
      return "Failed to connect to the AI service. Please check your API key.";
    }
  }

  // İleride, finansal veriyi analiz etmek için ek metotlar buraya eklenecek.
}