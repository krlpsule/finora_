// lib/screens/add_transaction.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/transaction/transaction_bloc.dart';
import '../features/transaction/transaction_event.dart';
import '../models/transaction_model.dart';

class AddTransactionPage extends StatefulWidget {

  final TransactionModel? editTx;

  const AddTransactionPage({super.key, this.editTx});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  
  bool _isIncome = false;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
    
      final newTransaction = TransactionModel(
        id: widget.editTx?.id, 
        amount: double.parse(_amountCtrl.text),
        category: _categoryCtrl.text,
        note: _noteCtrl.text,
        date: DateTime.now(), 
        isIncome: _isIncome,
      );

      
      final bloc = BlocProvider.of<TransactionBloc>(context);

      if (widget.editTx == null) {
       
        bloc.add(AddTransactionEvent(newTransaction));
      } else {
       
        bloc.add(UpdateTransactionEvent(newTransaction));
      }

     
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
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Expense'),
                  Switch(
                    value: _isIncome,
                    onChanged: (val) {
                      setState(() {
                        _isIncome = val; 
                      });
                    },
                  ),
                  Text('Income'),
                ],
              ),
              const SizedBox(height: 20),

              
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

              
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

             
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
