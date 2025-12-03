import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String? id;
  double amount;
  String category;
  String? note;
  DateTime date;
  bool isIncome;

  TransactionModel({
     this.id,
    required this.amount,
    required this.category,
     this.note,
    required this.date,
    this.isIncome = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
      'isIncome': isIncome,
    };
  }

  factory TransactionModel.fromDocument(String id, Map<String, dynamic> data) {
    return TransactionModel(
      id: id,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] ?? 'Uncategorized',
      note: data['note'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      isIncome: data['isIncome'] ?? false,
    );
  }
}
