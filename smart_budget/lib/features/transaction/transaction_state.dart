// lib/features/transaction/transaction_state.dart

import '../../models/transaction_model.dart';

abstract class TransactionState {
  const TransactionState();
}

// 1. Başlangıç Durumu
class TransactionInitial extends TransactionState {}

// 2. İşlem Yapılırken (Yükleniyor)
class TransactionLoading extends TransactionState {}

// 3. Veriler Başarıyla Yüklendi ve Gerçek Zamanlı Akıyor
class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  const TransactionLoaded(this.transactions);
}

// 4. İşlem (CRUD) veya Yükleme Sırasında Hata Oluştu
class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);
}

// 5. Bir işlem başarıyla tamamlandı (örneğin Ekleme/Silme sonrası)
class TransactionActionSuccess extends TransactionLoaded {
  const TransactionActionSuccess(List<TransactionModel> transactions)
      : super(transactions);
}