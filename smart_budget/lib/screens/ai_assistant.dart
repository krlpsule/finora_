import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';

class AIAssistantScreen extends StatefulWidget {
  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  @override
  Widget build(BuildContext context) {
    final ai = Provider.of<AIService>(context, listen: false);
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('AI Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: _messages.map((m) => ListTile(
                title: Align(
                  alignment: m['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: m['role'] == 'user' ? Colors.indigo[50] : Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: Text(m['text']!),
                  ),
                ),
              )).toList(),
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: InputDecoration(hintText: 'Ask something...'))),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    final txt = _controller.text.trim();
                    if (txt.isEmpty) return;
                    setState(() => _messages.add({'role': 'user', 'text': txt}));
                    _controller.clear();
                    final response = await ai.askAssistant(txt);
                    setState(() => _messages.add({'role': 'assistant', 'text': response}));
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
