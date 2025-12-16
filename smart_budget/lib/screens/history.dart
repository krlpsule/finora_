// lib/screens/history.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Ensure you have intl package or use basic split
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: fs.streamTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data!;
          if (list.isEmpty) {
            return _buildEmptyState();
          }

          // Sort by date descending
          list.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (ctx, idx) {
              final tx = list[idx];
              final bool isNewDay = idx == 0 ||
                  !_isSameDay(list[idx - 1].date, tx.date);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isNewDay) _buildDateHeader(tx.date),
                  _buildTransactionItem(context, tx, fs),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    // You can use DateFormat from intl package here for better formatting
    final dateStr = "${date.day}/${date.month}/${date.year}";
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        dateStr,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      BuildContext context, TransactionModel tx, FirestoreService fs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: tx.isIncome 
              ? const Color(0xFFE3F9E5) 
              : const Color(0xFFFFEBEB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward, // Income usually arrow in
            color: tx.isIncome ? Colors.green[700] : Colors.red[700],
            size: 24,
          ),
        ),
        title: Text(
          tx.category,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tx.note != null && tx.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  tx.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              (tx.isIncome ? "+ " : "- ") + "₺${tx.amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 16,
                color: tx.isIncome ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => fs.deleteTransaction(tx.id!),
              child: const Text(
                "Delete",
                style: TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
