// lib/models/transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String? id;
  String userId; // 🚨 NEW: Stores the unique ID of the user who owns this transaction
  String title;
  double amount;
  String category;
  String? note;
  DateTime date;
  bool isIncome;

  TransactionModel({
    this.id,
    required this.userId, // 🚨 NEW: Required in constructor
    required this.title,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    this.isIncome = false,
  });

  // 1. Convert to Map for Firestore (Saving)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId, // 🚨 NEW: Save userId to database
      'title': title,
      'amount': amount,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
      'isIncome': isIncome,
    };
  }

  // 2. Read from Firestore (Loading)
  factory TransactionModel.fromDocument(String id, Map<String, dynamic> data) {
    return TransactionModel(
      id: id,
      userId: data['userId'] ?? '', // 🚨 NEW: Read userId (default to empty string if missing)
      title: data['title'] ?? 'Unknown Title',
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] ?? 'Uncategorized',
      note: data['note'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      isIncome: data['isIncome'] ?? false,
    );
  }

  // 3. Factory Method for Statement Import (Parsing)
  factory TransactionModel.fromMapForImport(Map<String, dynamic> map) {
    // ⚠️ Date Conversion: Parse string dates like '15/12/2025'
    DateTime parsedDate;
    try {
      final dateString = map['date'].toString();
      final parts = dateString.split(RegExp(r'[/\.-]'));
      
      // Assumes DD/MM/YYYY format
      if (parts.length >= 3) {
        parsedDate = DateTime(
          int.parse(parts[2]), // Year
          int.parse(parts[1]), // Month
          int.parse(parts[0]), // Day
        );
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now(); 
    }

    final typeString = map['type'].toString().toLowerCase();
    final isIncome = typeString == 'income' || typeString == 'gelir'; 
    final category = map['category'] as String? ?? 'Imported'; 

    return TransactionModel(
      id: null,
      userId: '', // 🚨 NEW: Empty initially during import, populated later by FirestoreService
      title: map['title'] as String? ?? 'Imported Transaction',
      amount: (map['amount'] as num?)?.abs().toDouble() ?? 0.0,
      category: category, 
      note: 'Imported via ' + typeString, 
      date: parsedDate,
      isIncome: isIncome,
    );
  }

  // 4. 🚨 NEW: copyWith Method
  // Essential for updating properties (like userId) of an immutable object instance.
  // Useful when processing imported lists before saving to Firebase.
  TransactionModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    bool? isIncome,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}