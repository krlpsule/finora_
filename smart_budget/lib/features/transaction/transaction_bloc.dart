// lib/features/transaction/transaction_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/firestore_service.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';
import '../../models/transaction_model.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final FirestoreService _firestoreService;
  StreamSubscription? _transactionsSubscription; 
  TransactionBloc(this._firestoreService) : super(TransactionInitial()) {
    
    on<LoadTransactions>(_onLoadTransactions);
    on<TransactionsUpdated>(_onTransactionsUpdated);
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
  }

  
  void _onLoadTransactions(
      LoadTransactions event, Emitter<TransactionState> emit) {
    _transactionsSubscription?.cancel(); 
    emit(TransactionLoading());

    
    _transactionsSubscription = _firestoreService.streamTransactions().listen(
      (transactions) {
        add(TransactionsUpdated(transactions));
      },
      onError: (error) {
        emit(TransactionError('Veriler yüklenirken bir hata oluştu: $error'));
      },
    );
  }


  void _onTransactionsUpdated(
      TransactionsUpdated event, Emitter<TransactionState> emit) {
    emit(TransactionLoaded(event.transactions));
  }

  
  void _onAddTransaction(
      AddTransactionEvent event, Emitter<TransactionState> emit) async {
    try {
      
      await _firestoreService.addTransaction(event.transaction);
    } catch (e) {
      
      final currentState = state;
      if (currentState is TransactionLoaded) {
        emit(TransactionError('İşlem eklenirken hata oluştu: $e'));
        emit(currentState);
      } else {
        emit(TransactionError('İşlem eklenirken hata oluştu: $e'));
      }
    }
  }

  void _onDeleteTransaction(
      DeleteTransactionEvent event, Emitter<TransactionState> emit) async {
    try {
      await _firestoreService.deleteTransaction(event.transactionId);
    } catch (e) {
      final currentState = state;
      if (currentState is TransactionLoaded) {
        emit(TransactionError('İşlem silinirken hata oluştu: $e'));
        emit(currentState);
      } else {
        emit(TransactionError('İşlem silinirken hata oluştu: $e'));
      }
    }
  }

  void _onUpdateTransaction(
      UpdateTransactionEvent event, Emitter<TransactionState> emit) async {
    try {
      await _firestoreService.updateTransaction(event.transaction);
    } catch (e) {
      final currentState = state;
      if (currentState is TransactionLoaded) {
        emit(TransactionError('İşlem güncellenirken hata oluştu: $e'));
        emit(currentState);
      } else {
        emit(TransactionError('İşlem güncellenirken hata oluştu: $e'));
      }
    }
  }

  
  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}
