// lib/screens/ai_assistant.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
        "Finora Assistant: Hello! How can I help you manage your finances today?");
  }

  void _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    // Kullanıcı mesajını ekle
    setState(() {
      _messages.add("You: $query");
      _controller.clear();
      _isLoading = true;
    });

    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      final response = await aiService.getResponse(query);

      // AI yanıtını ekle
      setState(() {
        _messages.add("Finora Assistant: $response");
      });
    } catch (e) {
      setState(() {
        _messages.add(
            "Finora Assistant: An error occurred while fetching the response.");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Column(
        children: [
          // 1. Mesaj Listesi (Chat Geçmişi)
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(message,
                      style: TextStyle(
                        fontWeight: message.startsWith("You:")
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: message.startsWith("You:")
                            ? Colors.blueGrey.shade800
                            : Colors.indigo.shade800,
                      )),
                );
              },
            ),
          ),

          // 2. Yükleniyor Göstergesi
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          // 3. Giriş Alanı
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your finances...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
