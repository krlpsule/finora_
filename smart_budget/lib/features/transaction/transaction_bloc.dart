// lib/features/transaction/transaction_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/firestore_service.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';
import '../../models/transaction_model.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final FirestoreService _firestoreService;
  StreamSubscription? _transactionsSubscription; // Gerçek zamanlı dinleyici

  TransactionBloc(this._firestoreService) : super(TransactionInitial()) {
    // --- Event Handler Tanımları ---
    on<LoadTransactions>(_onLoadTransactions);
    on<TransactionsUpdated>(_onTransactionsUpdated);
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
  }

  // --- HANDLERS (Olay İşleyicileri) ---

  // İşlemleri yükle ve gerçek zamanlı stream'i başlat
  void _onLoadTransactions(
      LoadTransactions event, Emitter<TransactionState> emit) {
    _transactionsSubscription?.cancel(); // Önceki dinleyiciyi kapat
    emit(TransactionLoading());

    // Firestore stream'ini başlat ve gelen veriyi TransactionsUpdated Event'i ile BLoC'a geri gönder
    _transactionsSubscription = _firestoreService.streamTransactions().listen(
      (transactions) {
        add(TransactionsUpdated(transactions));
      },
      onError: (error) {
        emit(TransactionError('Veriler yüklenirken bir hata oluştu: $error'));
      },
    );
  }

  // Stream'den gelen yeni veriyi State olarak UI'a yayınla
  void _onTransactionsUpdated(
      TransactionsUpdated event, Emitter<TransactionState> emit) {
    emit(TransactionLoaded(event.transactions));
  }

  // Yeni İşlem Ekleme
  void _onAddTransaction(
      AddTransactionEvent event, Emitter<TransactionState> emit) async {
    try {
      // Servisi çağır. Firestore işlemi tamamlanınca stream otomatik olarak yeni veriyi çekecek.
      await _firestoreService.addTransaction(event.transaction);
    } catch (e) {
      // Hata durumunda, mevcut veriyi koruyarak hata mesajı yayınla
      final currentState = state;
      if (currentState is TransactionLoaded) {
        emit(TransactionError('İşlem eklenirken hata oluştu: $e'));
        emit(currentState);
      } else {
        emit(TransactionError('İşlem eklenirken hata oluştu: $e'));
      }
    }
  }

  // İşlem Silme (Diğer CRUD işlemlerine benzer)
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

  // İşlem Güncelleme
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

  // BLoC kapatılırken stream'i durdur
  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}
