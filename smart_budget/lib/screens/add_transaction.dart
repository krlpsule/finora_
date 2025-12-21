// lib/screens/add_transaction.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Required for User ID
import '../features/transaction/transaction_bloc.dart';
import '../features/transaction/transaction_event.dart';
import '../models/transaction_model.dart';

class AddTransactionPage extends StatefulWidget {
  // If editTx is provided, we are in "Edit Mode", otherwise "Add Mode"
  final TransactionModel? editTx;

  const AddTransactionPage({super.key, this.editTx});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture user input
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // Toggle for Income/Expense (Default is Expense)
  bool _isIncome = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form if editing an existing transaction
    if (widget.editTx != null) {
      _amountCtrl.text = widget.editTx!.amount.toString();
      _categoryCtrl.text = widget.editTx!.category;
      _noteCtrl.text = widget.editTx!.note ?? '';
      _isIncome = widget.editTx!.isIncome;
    }
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Get current user ID (safety check, though Service handles the actual assignment)
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Determine the title: Use Note if available, otherwise use Category
      final transactionTitle = _noteCtrl.text.isNotEmpty 
          ? _noteCtrl.text 
          : _categoryCtrl.text;

      // Create the Transaction Model
      final newTransaction = TransactionModel(
        id: widget.editTx?.id, // Keep ID if editing, null if new
        userId: uid, // 🚨 NEW: Required field (filled with current UID)
        title: transactionTitle, // 🚨 Logic: Note -> Category -> Title
        amount: double.parse(_amountCtrl.text),
        category: _categoryCtrl.text,
        note: _noteCtrl.text,
        date: widget.editTx?.date ?? DateTime.now(), // Keep original date if editing
        isIncome: _isIncome,
      );

      final bloc = BlocProvider.of<TransactionBloc>(context);

      if (widget.editTx == null) {
        // Add Mode
        bloc.add(AddTransactionEvent(newTransaction));
      } else {
        // Edit Mode
        bloc.add(UpdateTransactionEvent(newTransaction));
      }

      // Close the screen
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
              // 1. Transaction Type Toggle (Expense vs Income)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Expense', 
                      style: TextStyle(
                          fontWeight: !_isIncome ? FontWeight.bold : FontWeight.normal,
                          color: !_isIncome ? Colors.red : Colors.black)),
                  Switch(
                    value: _isIncome,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    onChanged: (val) {
                      setState(() {
                        _isIncome = val;
                      });
                    },
                  ),
                  Text('Income',
                      style: TextStyle(
                          fontWeight: _isIncome ? FontWeight.bold : FontWeight.normal,
                          color: _isIncome ? Colors.green : Colors.black)),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Amount Input
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₺ ',
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

              // 3. Category Input
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

              // 4. Note/Description Input
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Used as title if provided',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // 5. Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  widget.editTx == null ? 'SAVE' : 'UPDATE',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}