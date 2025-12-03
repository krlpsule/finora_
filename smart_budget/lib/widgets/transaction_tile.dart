import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  TransactionTile({required this.tx, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final amountText = (tx.isIncome ? '+ ' : '- ') + tx.amount.toStringAsFixed(2) + '₺';
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(tx.category[0].toUpperCase()),
        ),
        title: Text(tx.category),
        subtitle: Text((tx.note ?? '') + ' • ' + DateFormat.yMMMd().format(tx.date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(amountText, style: TextStyle(fontWeight: FontWeight.bold, color: tx.isIncome ? Colors.green : Colors.red)),
            SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.edit, size: 18), onPressed: onEdit),
                IconButton(icon: Icon(Icons.delete, size: 18), onPressed: onDelete),
              ],
            )
          ],
        ),
      ),
    );
  }
}
