// lib/screens/ai_assistant.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../services/speech_service.dart';
import '../models/transaction_model.dart'; // Eğer veriyi göndereceksek lazım

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = []; // Mesajlar listesi
  bool _isLoading = false;
  
  // SpeechService'i Provider ile almak yerine burada başlatabiliriz veya Provider'dan alabiliriz.
  // Varsayılan olarak Provider ile almayı tercih edelim.
  late SpeechService _speechService;

  @override
  void initState() {
    super.initState();
    _messages.add({"role": "assistant", "text": "Hello! I am Finora AI. Ask me about your finances or a general query."});
    // SpeechService init işlemi initSpeech() metodunda yapılacak
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider'ı burada alıp SpeechService'i başlatmak daha güvenlidir
    _speechService = Provider.of<SpeechService>(context, listen: false);
    _speechService.initSpeech();
  }

  // PRD R5.1.3: Mesaj gönderme ve AI'dan yanıt alma
  void _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    
    // Kullanıcı mesajını ekle
    setState(() {
      _messages.add({"role": "user", "text": query});
      _controller.clear();
      _isLoading = true;
    });

    // Otomatik aşağı kaydırma
    _scrollToBottom();
    
    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      
      // NOT: Gerçek uygulamada, tüm işlem verilerini (TransactionModel listesini)
      // bu sorguyla birlikte göndermelisiniz ki AI analiz yapabilsin. 
      // Şimdilik sadece sorguyu gönderiyoruz.
      final response = await aiService.getResponse(query);
      
      // AI yanıtını ekle
      setState(() {
        _messages.add({"role": "assistant", "text": response});
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "text": "An error occurred while fetching the response: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }
  
  // PRD R5.3: Sesli Komutu Başlatma
  void _startVoiceInput() async {
    if (_speechService.isAvailable && !_speechService.isListening) {
      final speechResult = await _speechService.startListening();
      if (speechResult != null && speechResult.isNotEmpty) {
        _controller.text = speechResult;
        _sendMessage(); // Sesli komutu AI'a gönder
      }
    } else {
      // Kullanıcıya izin hatası veya servis uygun değil mesajı göster
       setState(() {
        _messages.add({"role": "assistant", "text": "Voice input is not available. Check microphone permissions."});
      });
      _scrollToBottom();
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // MainScreen'de AppBar'ı yönettiğimiz için burada null yaptık.
    return Scaffold(
      appBar: null, 
      body: Column(
        children: [
          // 1. Mesaj Listesi (Chat Geçmişi)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["role"] == "user";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12).copyWith(
                        topRight: isUser ? const Radius.circular(0) : const Radius.circular(12),
                        topLeft: isUser ? const Radius.circular(12) : const Radius.circular(0),
                      ),
                    ),
                    child: Text(
                      message["text"] ?? "",
                      style: TextStyle(color: isUser ? Colors.blue.shade900 : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 2. Yükleniyor Göstergesi
          if (_isLoading)
            const LinearProgressIndicator(),

          // 3. Giriş Alanı ve Mikrofon Butonu (PRD R5.3)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Mikrofon Butonu
                IconButton(
                  icon: Icon(
                    _speechService.isListening ? Icons.mic : Icons.mic_none,
                    color: _speechService.isListening ? Colors.red : Theme.of(context).primaryColor,
                  ),
                  onPressed: _isLoading ? null : _startVoiceInput,
                ),
                
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your finances or a command...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                
                // Gönder Butonu
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