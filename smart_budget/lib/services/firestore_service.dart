// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Required to get the current user
import '../models/transaction_model.dart';

class FirestoreService {
  // Instances for Firestore Database and Firebase Authentication
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Adds a new transaction to the 'transactions' collection.
  /// Automatically assigns the current User ID to the transaction for privacy.
  Future<void> addTransaction(TransactionModel transaction) async {
    final user = _auth.currentUser;

    if (user == null) {
      // If no user is logged in, we cannot save the transaction securely.
      print("Warning: Attempted to add transaction without a logged-in user.");
      return;
    }

    // Create a copy of the transaction with the correct userId attached
    final newTransaction = transaction.copyWith(userId: user.uid);

    // Save to Firestore
    await _db.collection('transactions').add(newTransaction.toMap());
  }

  /// Updates an existing transaction in Firestore.
  Future<void> updateTransaction(TransactionModel transaction) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Ensure we are updating a document that belongs to the current user (security check)
    // Note: In a production app, strict Security Rules in Firestore are also required.
    if (transaction.userId != user.uid) {
      print(
          "Warning: Attempted to update a transaction belonging to another user.");
      return;
    }

    await _db
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  /// Deletes a transaction by its ID.
  Future<void> deleteTransaction(String id) async {
    // Optional: You could fetch the doc first to verify ownership before deleting.
    await _db.collection('transactions').doc(id).delete();
  }

  /// Listens to the stream of transactions for the CURRENT USER only.
  /// Sorts them by date (descending).
  Stream<List<TransactionModel>> streamTransactions() {
    final user = _auth.currentUser;

    // If user is not logged in, return an empty list stream
    if (user == null) {
      return Stream.value([]);
    }

    // 🚨 KEY CHANGE: Added .where('userId', isEqualTo: user.uid)
    // This ensures users only see their own data.
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Convert Firestore document to TransactionModel
        return TransactionModel.fromDocument(doc.id, doc.data());
      }).toList();
    });
  }
}
