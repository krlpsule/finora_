// lib/screens/dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/transaction/transaction_bloc.dart';
import '../features/transaction/transaction_state.dart';
import '../widgets/transaction_tile.dart';
import '../models/transaction_model.dart';
import 'add_transaction.dart';
import '../features/transaction/transaction_event.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});


  void _openAddTransactionScreen(BuildContext context,
      {TransactionModel? txToEdit}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => AddTransactionPage(editTx: txToEdit)),
    );
  }

  Map<String, double> _calculateSummary(List<TransactionModel> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var tx in transactions) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    double balance = totalIncome - totalExpense;
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': balance,
    };
  }

  @override
  Widget build(BuildContext context) {
    final transactionBloc = context.read<TransactionBloc>();

    
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading || state is TransactionInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TransactionError) {
          return Center(
              child: Text('Error: ${state.message}',
                  style: const TextStyle(color: Colors.red)));
        }

        if (state is TransactionLoaded) {
          final transactions = state.transactions;
          final summary = _calculateSummary(transactions); 

          return CustomScrollView(
            slivers: [
           
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSummaryCard(context, summary),
                ),
              ),

              
              const SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

             
              transactions.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text('No transactions recorded yet.'),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, index) {
                          final tx = transactions[index];
                          return TransactionTile(
                            tx: tx,
                            
                            onEdit: () => _openAddTransactionScreen(context,
                                txToEdit: tx),
                            onDelete: () {
                             
                              transactionBloc
                                  .add(DeleteTransactionEvent(tx.id!));
                            },
                          );
                        },
                        childCount: transactions.length,
                      ),
                    ),
            ],
          );
        }

        return const Center(child: Text('Waiting for data...'));
      },
    );
  }

  
  Widget _buildSummaryCard(BuildContext context, Map<String, double> summary) {
    const double radius = 12.0;

    return Card(
      elevation: 4,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Balance',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              '₺${summary['balance']!.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  icon: Icons.arrow_downward,
                  label: 'Expense',
                  amount: summary['expense']!,
                  color: Colors.red.shade100,
                ),
                _buildSummaryItem(
                  icon: Icons.arrow_upward,
                  label: 'Income',
                  amount: summary['income']!,
                  color: Colors.green.shade100,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        Text(
          '₺${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
