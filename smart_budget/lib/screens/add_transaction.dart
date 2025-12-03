// lib/screens/add_transaction.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/transaction/transaction_bloc.dart';
import '../features/transaction/transaction_event.dart';
import '../models/transaction_model.dart';

class AddTransactionPage extends StatefulWidget {
  // Düzenleme (Edit) modunda kullanmak için (PRD 5.4)
  final TransactionModel? editTx;

  const AddTransactionPage({super.key, this.editTx});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  // Kontrolcüler (Controllers)
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // İşlem Tipi (Varsayılan Gider: False = isIncome, True = isExpense)
  bool _isIncome = false;

  // Formu Gönderme Metodu
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // 1. Yeni TransactionModel nesnesini oluştur
      final newTransaction = TransactionModel(
        id: widget.editTx?.id, // Eğer düzenleme yapılıyorsa ID'yi kullan
        amount: double.parse(_amountCtrl.text),
        category: _categoryCtrl.text,
        note: _noteCtrl.text,
        date: DateTime.now(), // Şu anki tarih
        isIncome: _isIncome,
      );

      // 2. BLoC'a erişim sağla ve Event'i gönder
      final bloc = BlocProvider.of<TransactionBloc>(context);

      if (widget.editTx == null) {
        // Yeni işlem ekleme
        bloc.add(AddTransactionEvent(newTransaction));
      } else {
        // Mevcut işlemi düzenleme
        bloc.add(UpdateTransactionEvent(newTransaction));
      }

      // 3. Formu kapat ve ana sayfaya dön
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.editTx == null ? 'New Transaction' : 'Edit Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. İşlem Tipi Seçimi ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Expense'),
                  Switch(
                    value: _isIncome,
                    onChanged: (val) {
                      setState(() {
                        _isIncome = val; // True ise Gelir, False ise Gider
                      });
                    },
                  ),
                  Text('Income'),
                ],
              ),
              const SizedBox(height: 20),

              // --- 2. Tutar Girişi ---
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₺',
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      double.tryParse(value) == null) {
                    return 'Please enter a valid amount.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- 3. Kategori Girişi ---
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category (e.g., Food, Salary)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Category cannot be empty.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- 4. Not Girişi ---
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // --- 5. Kaydet Butonu ---
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.editTx == null ? 'SAVE' : 'EDİT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
