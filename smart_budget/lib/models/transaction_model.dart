// lib/models/transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String? id;
  String userId; 
  String title;
  double amount;
  String category;
  String? note;
  DateTime date;
  bool isIncome;

  TransactionModel({
    this.id,
    required this.userId,
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
      'userId': userId,
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
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Bilinmeyen Başlık',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'Genel',
      note: data['note'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      isIncome: data['isIncome'] ?? false,
    );
  }

  // 3. Factory Method for Statement Import (Parsing)
  // DÜZELTME BURADA YAPILDI
  factory TransactionModel.fromMapForImport(Map<String, dynamic> map) {
    // ⚠️ Tarih Çevirme İşlemi
    DateTime parsedDate;
    try {
      final dateString = map['date'].toString();
      final parts = dateString.split(RegExp(r'[/\.-]'));
      
      if (parts.length >= 3) {
        // Genellikle format GG/AA/YYYY şeklindedir
        parsedDate = DateTime(
          int.parse(parts[2]), // Yıl
          int.parse(parts[1]), // Ay
          int.parse(parts[0]), // Gün
        );
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now(); 
    }

    // ⚠️ Başlık (Title) Çevirme İşlemi (Sorunun Çözümü)
    // map['title'] değerini güvenli bir şekilde String'e çeviriyoruz.
    // Eğer 'title' boşsa veya null ise 'Imported Transaction' yazar.
    String parsedTitle = map['title']?.toString() ?? '';
    if (parsedTitle.trim().isEmpty) {
      parsedTitle = 'Imported Transaction';
    }

    // Tür ve Kategori Belirleme
    final typeString = map['type']?.toString().toLowerCase() ?? 'expense';
    final isIncome = typeString == 'income' || typeString == 'gelir'; 
    
    // Kategori varsayılan olarak 'Imported' kalır, ancak başlık (title) artık "Elif Cafe" olacaktır.
    final category = map['category'] as String? ?? 'Imported'; 

    return TransactionModel(
      id: null,
      userId: '', // Bloc tarafında doldurulacak
      title: parsedTitle, // Artık "Elif Cafe" gibi gerçek isim gelecek
      amount: (map['amount'] as num?)?.abs().toDouble() ?? 0.0,
      category: category, 
      note: 'Otomatik içe aktarıldı ($typeString)', 
      date: parsedDate,
      isIncome: isIncome,
    );
  }

  // 4. copyWith Method
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