import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'transactions';
  final _uuid = Uuid();

  Future<void> addTransaction(TransactionModel tx) async {
    final id = _uuid.v4();
    await _db.collection(_collection).doc(id).set(tx.toMap());
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    await _db.collection(_collection).doc(tx.id).update(tx.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  Stream<List<TransactionModel>> streamTransactions() {
    return _db.collection(_collection)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => TransactionModel.fromDocument(d.id, d.data())).toList());
  }

  Future<List<TransactionModel>> fetchTransactionsOnce() async {
    final snap = await _db.collection(_collection).orderBy('date', descending: true).get();
    return snap.docs.map((d) => TransactionModel.fromDocument(d.id, d.data())).toList();
  }
}
