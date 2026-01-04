// lib/features/transaction/transaction_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/transaction_model.dart';
import '../../services/firestore_service.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final FirestoreService _firestoreService;

  TransactionBloc(this._firestoreService) : super(TransactionLoading()) {
    // 1. Load Transactions (DÜZELTİLDİ)
    on<LoadTransactions>((event, emit) async {
      emit(TransactionLoading());

      await emit.forEach<List<TransactionModel>>(
        _firestoreService.streamTransactions(),
        onData: (transactions) {
          return TransactionLoaded(transactions);
        },
        onError: (error, stackTrace) {
          if (error.toString().contains("permission-denied") ||
              error.toString().contains("insufficient permissions")) {
            return TransactionLoaded([]); // Sessizce boş liste döndür
          }

          return TransactionError("Failed to load transactions: $error");
        },
      );
    });

    // 2. Add Transaction
    on<AddTransactionEvent>((event, emit) async {
      try {
        await _firestoreService.addTransaction(event.transaction);
      } catch (e) {
        emit(TransactionError("Failed to add transaction: $e"));
      }
    });

    // 3. Update Transaction
    on<UpdateTransactionEvent>((event, emit) async {
      try {
        await _firestoreService.updateTransaction(event.transaction);
      } catch (e) {
        emit(TransactionError("Failed to update transaction: $e"));
      }
    });

    // 4. Delete Transaction
    on<DeleteTransactionEvent>((event, emit) async {
      try {
        await _firestoreService.deleteTransaction(event.id);
      } catch (e) {
        emit(TransactionError("Failed to delete transaction: $e"));
      }
    });
  }
}
