// lib/services/ai_chat_provider.dart

import 'package:flutter/material.dart';

class AIChatProvider extends ChangeNotifier {

  final List<Map<String, String>> _messages = [
    {
      "role": "assistant",
      "text":
          "Hello! I am Finora AI. Ask me about your finances or a general query."
    }
  ];
  bool _isLoading = false;


  List<Map<String, String>> get messages => _messages;
  bool get isLoading => _isLoading;


  void addMessage(Map<String, String> message) {
    _messages.add(message);
    notifyListeners(); 
  }

 
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners(); 
  }

 
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
