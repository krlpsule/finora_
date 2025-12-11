// lib/widgets/transaction_tile.dart 

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;

    
    final subtitleText =
        tx.note?.isNotEmpty == true ? tx.note! : 'No description';

    return SizedBox(
      
      height: 70.0,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: InkWell(
          onTap: onEdit, 
          onLongPress: () =>
              _showDeleteDialog(context), 
          child: ListTile(
            
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),

            leading: Icon(
              isIncome ? Icons.attach_money : Icons.money_off,
              color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
            ),

            title: Text(
              tx.category,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            subtitle: Text(
              subtitleText,
              overflow: TextOverflow.ellipsis,
            ),

            
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                Text(
                  '${isIncome ? '+' : '-'} ₺${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        isIncome ? Colors.green.shade700 : Colors.red.shade700,
                    fontSize: 17.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 8),

                
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.grey),
                  onPressed: () => _showDeleteDialog(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete(); 
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
