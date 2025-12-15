// lib/screens/ai_assistant.dart (Nihai Versiyon)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../services/speech_service.dart';
import '../models/transaction_model.dart';
import '../features/transaction/transaction_bloc.dart';
import '../features/transaction/transaction_state.dart';
import '../services/ai_chat_provider.dart'; 

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  

  late SpeechService _speechService;

  @override
  void initState() {
    super.initState();
    
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _speechService = Provider.of<SpeechService>(context, listen: false);
    _speechService.initSpeech();
  }

  
  void _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    
    final chatProvider = Provider.of<AIChatProvider>(context, listen: false);
    if (chatProvider.isLoading)
      return; 

   
    chatProvider.addMessage({"role": "user", "text": query});
    _controller.clear();
    chatProvider.setLoading(true);

    _scrollToBottom();

    
    final transactionState = context.read<TransactionBloc>().state;
    List<TransactionModel> transactions = [];
    if (transactionState is TransactionLoaded) {
      transactions = transactionState.transactions.take(100).toList();
    }

    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      final response =
          await aiService.getFinancialResponse(query, transactions);

      
      chatProvider.addMessage({"role": "assistant", "text": response});
    } catch (e) {
      chatProvider.addMessage({
        "role": "assistant",
        "text": "An error occurred while fetching the response: $e"
      });
    } finally {
      chatProvider.setLoading(false); 
      _scrollToBottom();
    }
  }

  
  void _startVoiceInput() async {
    final chatProvider = Provider.of<AIChatProvider>(context, listen: false);
    final originalText = _controller.text;

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
            _sendMessage();
          }
          setState(() {});
        },
        onListeningStatusChanged: () {
          setState(() {});
        },
        localeId: 'en_US',
      );

    
      await Future.delayed(const Duration(seconds: 6));

      if (_controller.text == originalText &&
          !_speechService.isListening &&
          !chatProvider.isLoading) {
        chatProvider.addMessage({
          "role": "assistant",
          "text":
              "I could not hear or understand your speech. Please try speaking clearly or use the keyboard.",
        });
        _scrollToBottom();
      }
    } else {
      chatProvider.addMessage({
        "role": "assistant",
        "text": "Voice input is not available. Check microphone permissions."
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
   
    final chatProvider = context.watch<AIChatProvider>();
    final messages = chatProvider.messages;
    final isLoading = chatProvider.isLoading;

    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length, 
              itemBuilder: (context, index) {
                final message = messages[index];
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
          if (isLoading) // <-- Provider'dan
            const LinearProgressIndicator(),
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
                  onPressed: isLoading ? null : _startVoiceInput,
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
                  onPressed:
                      isLoading ? null : _sendMessage, 
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}