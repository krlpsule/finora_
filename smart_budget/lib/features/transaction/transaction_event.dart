// lib/features/transaction/transaction_event.dart

import 'package:equatable/equatable.dart';
import '../../models/transaction_model.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object> get props => [];
}

// 1. Load Event (Start listening to stream)
class LoadTransactions extends TransactionEvent {}

// 2. Add Event
class AddTransactionEvent extends TransactionEvent {
  final TransactionModel transaction;

  const AddTransactionEvent(this.transaction);

  @override
  List<Object> get props => [transaction];
}

// 3. Update Event
class UpdateTransactionEvent extends TransactionEvent {
  final TransactionModel transaction;

  const UpdateTransactionEvent(this.transaction);

  @override
  List<Object> get props => [transaction];
}

// 4. 🚨 GÜNCELLENEN KISIM: Delete Event
// 'id' alanı zorunlu hale getirildi.
class DeleteTransactionEvent extends TransactionEvent {
  final String id; // Hata veren kısım burasıydı (id eksikti)

  const DeleteTransactionEvent(this.id);

  @override
  List<Object> get props => [id];
}