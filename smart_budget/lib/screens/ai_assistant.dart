// lib/screens/ai_assistant.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../services/speech_service.dart';
import '../models/transaction_model.dart';
import '../features/transaction/transaction_bloc.dart';
import '../features/transaction/transaction_state.dart'; // <-- KRİTİK: TransactionsLoaded için eklendi

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  late SpeechService _speechService;

  @override
  void initState() {
    super.initState();
    _messages.add({
      "role": "assistant",
      "text":
          "Hello! I am Finora AI. Ask me about your finances or a general query."
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _speechService = Provider.of<SpeechService>(context, listen: false);
    _speechService.initSpeech();
  }

  // Kullanıcı mesajını ekle ve AI'dan yanıt al
  void _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _isLoading) return;

    // Kullanıcı mesajını ekle
    setState(() {
      _messages.add({"role": "user", "text": query});
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    // --- Analiz için işlem verilerini al ---
    final transactionState = context.read<TransactionBloc>().state;
    List<TransactionModel> transactions = [];
    if (transactionState is TransactionLoaded) {
      // <-- Hata çözüldü
      transactions = transactionState.transactions.take(100).toList();
    }
    // ------------------------------------

    try {
      final aiService = Provider.of<AIService>(context, listen: false);

      // Hata Düzeltmesi: getFinancialResponse yerine getResponse kullandık
      final response = await aiService.getResponse(query);

      // AI yanıtını ekle
      setState(() {
        _messages.add({"role": "assistant", "text": response});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "text": "An error occurred while fetching the response: $e"
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // PRD R5.3: Sesli Komutu Başlatma (Düzeltilmiş Callback Yapısı)
  // lib/screens/ai_assistant.dart (Düzeltilmiş _startVoiceInput Metodu)

  void _startVoiceInput() async {
    final originalText = _controller.text; // Dinleme öncesi metni kaydet

    if (_speechService.isListening) {
      _speechService.stopListening();
      setState(() {});
      return;
    }

    if (_speechService.isAvailable && !_speechService.isListening) {
      setState(() {});

      await _speechService.startListening(
        onResult: (recognizedWords) {
          if (recognizedWords.isNotEmpty) {
            _controller.text = recognizedWords;
            // Bu aşamada _sendMessage() çağrıldığında text boş olmadığı için sorun olmaz.
            _sendMessage();
          }
          setState(() {});
        },
        onListeningStatusChanged: () {
          setState(() {});
        },
        localeId: 'en_US',
      );

      // --- KRİTİK EKLENTİ: Ses Tanıma Başarısızlığı Kontrolü ---

      // Dinleme tamamlandıktan sonra (muhtemelen 5 saniye sonra) kontrolü yap.
      // Güvenilir bir kontrol için dinleme durumunun bitmesini beklememiz gerekir.

      // NOT: Ses tanıma işlemi genellikle asenkron bittiği için,
      // direkt olarak burada kontrol etmek yerine, dinleme durumunun
      // bittiğinden emin olmalıyız. En basit yol, bir süre beklemektir.

      // Basit ve etkili kontrol: Dinleme durduğunda controller'da hala orijinal metin varsa
      // (yani yeni metin gelmediyse) hata mesajı göster.
      await Future.delayed(const Duration(
          seconds: 6)); // Dinleme süresinden biraz daha fazla bekle.

      if (_controller.text == originalText && !_speechService.isListening) {
        setState(() {
          _messages.add({
            "role": "assistant",
            "text":
                "I could not hear or understand your speech. Please try speaking clearly or use the keyboard.",
          });
        });
        _scrollToBottom();
      }
      // -----------------------------------------------------
    } else {
      setState(() {
        _messages.add({
          "role": "assistant",
          "text": "Voice input is not available. Check microphone permissions."
        });
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
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color:
                          isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12).copyWith(
                        topRight: isUser
                            ? const Radius.circular(0)
                            : const Radius.circular(12),
                        topLeft: isUser
                            ? const Radius.circular(12)
                            : const Radius.circular(0),
                      ),
                    ),
                    child: Text(
                      message["text"] ?? "",
                      style: TextStyle(
                          color:
                              isUser ? Colors.blue.shade900 : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _speechService.isListening ? Icons.mic : Icons.mic_none,
                    color: _speechService.isListening
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                  ),
                  onPressed: _isLoading ? null : _startVoiceInput,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your finances or a command...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25))),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
