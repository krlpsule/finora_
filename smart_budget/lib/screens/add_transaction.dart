import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/speech_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? editTx;
  AddTransactionScreen({this.editTx});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isIncome = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    if (widget.editTx != null) {
      final e = widget.editTx!;
      _amountCtrl.text = e.amount.toString();
      _categoryCtrl.text = e.category;
      _noteCtrl.text = e.note;
      _date = e.date;
      _isIncome = e.isIncome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final speech = Provider.of<SpeechService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text(widget.editTx == null ? 'Add Transaction' : 'Edit Transaction')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amount (₺)'),
                validator: (v) => v == null || v.isEmpty ? 'Enter amount' : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _categoryCtrl,
                decoration: InputDecoration(labelText: 'Category'),
                validator: (v) => v == null || v.isEmpty ? 'Enter category' : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _noteCtrl,
                decoration: InputDecoration(labelText: 'Note'),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text('Date: ${_date.toLocal().toString().split(' ')[0]}'),
                  Spacer(),
                  TextButton(onPressed: _pickDate, child: Text('Change'))
                ],
              ),
              SwitchListTile(
                title: Text('Is Income'),
                value: _isIncome,
                onChanged: (v) => setState(() => _isIncome = v),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.mic),
                    label: Text(_listening ? 'Stop Listen' : 'Voice Input'),
                    onPressed: () async {
                      if (!_listening) {
                        final ok = await speech.init();
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Speech not available')));
                          return;
                        }
                        setState(() => _listening = true);
                        speech.startListening((text) {
                          // very simple parsing: "spent 50 on food" -> amount/category
                          setState(() {
                            _noteCtrl.text = text;
                          });
                        });
                      } else {
                        speech.stopListening();
                        setState(() => _listening = false);
                      }
                    },
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.check),
                    label: Text('Save'),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final tx = TransactionModel(
                        id: widget.editTx?.id ?? '',
                        amount: double.tryParse(_amountCtrl.text) ?? 0,
                        category: _categoryCtrl.text,
                        note: _noteCtrl.text,
                        date: _date,
                        isIncome: _isIncome,
                      );
                      if (widget.editTx == null) {
                        await fs.addTransaction(tx);
                      } else {
                        await fs.updateTransaction(TransactionModel(
                          id: widget.editTx!.id,
                          amount: tx.amount,
                          category: tx.category,
                          note: tx.note,
                          date: tx.date,
                          isIncome: tx.isIncome,
                        ));
                      }
                      Navigator.pop(context);
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d != null) setState(() => _date = d);
  }
}
