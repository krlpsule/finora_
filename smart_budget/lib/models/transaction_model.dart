// lib/models/transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// TransactionModel class, including optional fields (id, note)
class TransactionModel {
  String? id; // Nullable for new entries before Firebase assigns an ID
  String title;
  double amount;
  String category;
  String? note; // Optional note field
  DateTime date;
  bool isIncome;

  TransactionModel({
    this.id,
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
      'title': title,
      'amount': amount,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date), // CRITICAL: Uses Timestamp as per your original design
      'isIncome': isIncome,
    };
  }

  // 2. Read from Firestore (Loading)
  // This factory method matches your original structure, taking ID and data Map separately.
  factory TransactionModel.fromDocument(String id, Map<String, dynamic> data) {
    return TransactionModel(
      id: id,
      title: data['title'] ?? 'Unknown Title',
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] ?? 'Uncategorized',
      note: data['note'] ?? '',
      date: (data['date'] as Timestamp).toDate(), // Reads Timestamp
      isIncome: data['isIncome'] ?? false,
    );
  }

  // 3. Factory Method for Statement Import (Parsing)
  // Converts a Map received from StatementParserService into a TransactionModel.
  factory TransactionModel.fromMapForImport(Map<String, dynamic> map) {
    // ⚠️ Date Conversion: Parses date string (e.g., '15/12/2025') into DateTime.
    DateTime parsedDate;
    try {
      final dateString = map['date'].toString();
      // Supports various delimiters: /, ., -
      final parts = dateString.split(RegExp(r'[/\.-]'));
      
      // Assumes DD/MM/YYYY format, adjust if bank statement uses YYYY/MM/DD
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
      // Use current date if parsing fails
      parsedDate = DateTime.now(); 
    }

    // Determine type (Income/Expense) from the parsed string
    final typeString = map['type'].toString().toLowerCase();
    final isIncome = typeString == 'income' || typeString == 'gelir'; // Handles both English/Turkish
    
    // Safety check for category (Imported if missing)
    final category = map['category'] as String? ?? 'Imported'; 

    return TransactionModel(
      // Set ID to null, allowing Firestore to assign the final ID during 'add'
      id: null, 
      title: map['title'] as String? ?? 'Imported Transaction',
      amount: (map['amount'] as num?)?.abs().toDouble() ?? 0.0,
      category: category, 
      note: 'Imported via ' + typeString, // Add a default note for imported items
      date: parsedDate,
      isIncome: isIncome,
    );
  }
}