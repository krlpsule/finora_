import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/transaction_model.dart';
import '../../services/firestore_service.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final FirestoreService _firestoreService;

  TransactionBloc(this._firestoreService) : super(TransactionLoading()) {
    
    // 1. Load Transactions (The Fix for "emit was called after handler completed")
    on<LoadTransactions>((event, emit) async {
      // Set state to loading initially
      emit(TransactionLoading());

      // 🚨 CRITICAL FIX: We use 'emit.forEach' instead of standard .listen().
      // This keeps the event handler alive while listening to the Firestore Stream.
      // If we don't use this, the handler closes immediately, causing a crash when data arrives later.
      await emit.forEach<List<TransactionModel>>(
        _firestoreService.streamTransactions(), // Listening to the real-time stream
        onData: (transactions) {
          if (transactions.isEmpty) {
            return TransactionEmpty(); // Show empty state if no data
          }
          return TransactionLoaded(transactions); // Show list if data exists
        },
        onError: (error, stackTrace) {
          // Handle any Firestore errors (e.g., permission denied, network issues)
          return TransactionError("Failed to load transactions: $error");
        },
      );
    });

    // 2. Add Transaction
    on<AddTransactionEvent>((event, emit) async {
      try {
        await _firestoreService.addTransaction(event.transaction);
        // Note: We do NOT need to emit a new state here manually.
        // Because we are listening to the stream above, Firestore will automatically
        // notify the 'LoadTransactions' handler when a new item is added.
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