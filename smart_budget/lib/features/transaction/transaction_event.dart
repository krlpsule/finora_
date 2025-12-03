// lib/features/transaction/transaction_event.dart

import '../../models/transaction_model.dart';
// Eğer pubspec.yaml'a equatable eklediyseniz, bunu da import edin:
// import 'package:equatable/equatable.dart';

// Tüm Event'ler bu sınıfı miras alır. Equatable kullanıyorsanız, Equatable'ı miras alsın.
abstract class TransactionEvent {}

// 1. İşlemleri başlat ve stream'i dinlemeye başla
class LoadTransactions extends TransactionEvent {}

// 2. Yeni bir işlem ekle
class AddTransactionEvent extends TransactionEvent {
  final TransactionModel transaction;
  AddTransactionEvent(this.transaction);
}

// 3. İşlemi sil
class DeleteTransactionEvent extends TransactionEvent {
  final String transactionId;
  DeleteTransactionEvent(this.transactionId);
}

// 4. İşlemi güncelle
class UpdateTransactionEvent extends TransactionEvent {
  final TransactionModel transaction;
  UpdateTransactionEvent(this.transaction);
}

// 5. Stream'den yeni veri geldiğinde BLoC'u bilgilendirir (Dahili Event)
class TransactionsUpdated extends TransactionEvent {
  final List<TransactionModel> transactions;
  TransactionsUpdated(this.transactions);
}
