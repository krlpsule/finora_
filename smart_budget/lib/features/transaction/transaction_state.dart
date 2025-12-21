// lib/features/transaction/transaction_state.dart

import 'package:equatable/equatable.dart';
import '../../models/transaction_model.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object> get props => [];
}

// 1. Initial State
class TransactionInitial extends TransactionState {}

// 2. Loading State (Spinner shows up)
class TransactionLoading extends TransactionState {}

// 3. Loaded State (Data exists)
class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;

  const TransactionLoaded(this.transactions);

  @override
  List<Object> get props => [transactions];
}

// 4. 🚨 EKLENEN KISIM: Empty State (No data found)
// Veritabanı boşsa bu state çalışır.
class TransactionEmpty extends TransactionState {}

// 5. Error State
class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object> get props => [message];
}