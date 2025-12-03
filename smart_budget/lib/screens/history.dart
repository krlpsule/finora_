import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_tile.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text('History')),
      body: StreamBuilder<List<TransactionModel>>(
        stream: fs.streamTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final list = snapshot.data!;
          if (list.isEmpty) return Center(child: Text('No transactions'));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, idx) {
              final tx = list[idx];
              return TransactionTile(
                  tx: tx,
                  onDelete: () => fs.deleteTransaction(tx.id!),
                  onEdit: () {});
            },
          );
        },
      ),
    );
  }
}
