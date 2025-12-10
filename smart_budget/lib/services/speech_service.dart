// lib/services/speech_service.dart

import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/material.dart'; // <-- KRİTİK: VoidCallback için eklendi

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  
  bool get isAvailable => _speechToText.isAvailable;
  bool get isListening => _speechToText.isListening;

  Future<void> initSpeech() async {
    await _speechToText.initialize();
  }

  // PRD R5.3: Ses kaydını başlat ve sonucu callback ile döndür
  Future<void> startListening({
    required Function(String) onResult,
    // Dinleme durumu değiştiğinde çağrılacak opsiyonel callback
    VoidCallback? onListeningStatusChanged,
    String localeId = 'en_US', 
  }) async {
    if (!isAvailable) {
      await initSpeech();
    }
    
    if (isAvailable && !isListening) {
      
      // Dinleme durumu değişimlerini dinlemek için (ikona yansıtmak amacıyla)
      _speechToText.statusListener = (status) {
         if (onListeningStatusChanged != null) {
              onListeningStatusChanged();
         }
      };

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords); 
            stopListening();
          }
        },
        listenFor: const Duration(seconds: 5), 
        localeId: localeId,
      );
    }
  }
  
  void stopListening() {
    if (_speechToText.isListening) {
      _speechToText.stop();
      // stop çağrıldıktan sonra statusListener otomatik tetiklenir
    }
  }
}