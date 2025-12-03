// lib/services/speech_service.dart

import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  
  // Sınıf dışına açtığımız kontroller
  bool get isAvailable => _speechToText.isAvailable;
  bool get isListening => _speechToText.isListening;

  Future<void> initSpeech() async {
    // Ses servisinin uygunluğunu kontrol et ve başlat (izin ister)
    // Bu metodun dönüşü _speechToText.isAvailable değerini günceller.
    await _speechToText.initialize();
  }

  // PRD R5.3: Ses kaydını başlat ve sonucu döndür
  Future<String?> startListening() async {
    if (!isAvailable) {
      await initSpeech();
    }
    
    if (isAvailable && !isListening) {
      String? recognizedText;
      
      // Dinlemeyi başlatma ve bir callback ile sonucu yakalama
      _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            recognizedText = result.recognizedWords;
          }
        },
        listenFor: const Duration(seconds: 5), 
        // Burada dinleme başladığında hemen return yapmamak için dinleme tamamlanana kadar
        // bekleyen bir Stream yapısı kullanmak gerekir. Basitlik için dinlemeyi burada başlatıyoruz.
      );
      
      // Dinleme bitene kadar beklemek için manuel bir gecikme ekliyoruz.
      // Gerçek uygulamada, bu bekleme mantığı daha sofistike olmalıdır.
      await Future.delayed(const Duration(seconds: 5)); 
      
      return recognizedText;
    }
    return null;
  }
  
  void stopListening() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
  }
}