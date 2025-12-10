// lib/services/ai_chat_provider.dart

import 'package:flutter/material.dart';

class AIChatProvider extends ChangeNotifier {
  // Mesaj listesini ve ilk karşılama mesajını tutar
  final List<Map<String, String>> _messages = [
    {
      "role": "assistant",
      "text":
          "Hello! I am Finora AI. Ask me about your finances or a general query."
    }
  ];
  bool _isLoading = false;

  // Getter metotları
  List<Map<String, String>> get messages => _messages;
  bool get isLoading => _isLoading;

  // Mesaj ekleme metodu
  void addMessage(Map<String, String> message) {
    _messages.add(message);
    notifyListeners(); // UI'ı güncelle
  }

  // Yüklenme durumunu ayarlama metodu
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners(); // UI'ı güncelle
  }

  // Konuşmayı temizleme metodu (opsiyonel)
  void clearMessages() {
    _messages.clear();
    _messages.add({
      "role": "assistant",
      "text":
          "Hello! I am Finora AI. Ask me about your finances or a general query."
    });
    notifyListeners();
  }
}
