// lib/services/ai_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/transaction_model.dart';

class AIService {
  // 🚨 Hata Çözümü: _model tanımı burada olmalı
  late final GenerativeModel _model;
  
  AIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception("GEMINI_API_KEY not found in .env file.");
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: apiKey,
    );
  }

  // Genel sorgular için (opsiyonel)
  Future<String> getResponse(String userQuery) async {
    final response = await _model.generateContent([Content.text(userQuery)]);
    return response.text ?? "Sorry, I couldn't generate a response.";
  }

  // KRİTİK METOT: Finansal analiz ve veriye erişim için (Hata çözüldü)
  Future<String> getFinancialResponse(String userQuery, List<TransactionModel> transactions) async {
    
    // İşlem verilerini okunabilir bir metin formatına dönüştürme
    String transactionData = transactions.map((tx) => 
        'ID:${tx.id}, Type:${tx.isIncome ? "Income" : "Expense"}, Amount:${tx.amount.toStringAsFixed(2)}, Category:${tx.category}, Date:${tx.date.toIso8601String()}'
    ).join('\n');
    
    String fullPrompt = 
        "You are Finora AI, a helpful financial assistant. Your goal is to provide insightful, personalized advice and analysis based ONLY on the transaction data provided below. Do not assume any other data. Respond clearly and only in English.\n\n" +
        "USER QUERY: $userQuery\n\n" +
        "TRANSACTION DATA:\n$transactionData";
        
    try {
        final response = await _model.generateContent([Content.text(fullPrompt)]);
        return response.text ?? "Analysis failed. Please try again.";
    } catch (e) {
        return "An error occurred during analysis: $e";
    }
  }
}