// lib/screens/dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart'; 
import '../features/transaction/transaction_bloc.dart';
import '../features/transaction/transaction_state.dart';
import '../widgets/transaction_tile.dart';
import '../models/transaction_model.dart';
import 'add_transaction.dart';
import '../features/transaction/transaction_event.dart';
import '../services/statement_parser_service.dart'; 
import '../services/firestore_service.dart'; 

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _openAddTransactionScreen(BuildContext context,
      {TransactionModel? txToEdit}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => AddTransactionPage(editTx: txToEdit)),
    );
  }

  // --- LOGIC: Handle File Import ---
  Future<void> _handleImport(BuildContext context, FileTypeOption type) async {
    // 1. Close the bottom sheet
    Navigator.pop(context);

    // 2. Show loading feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Processing file... Please wait.")),
    );

    try {
      // 3. Use your Service to pick and parse
      final parser = StatementParserService();
      final List<Map<String, dynamic>> rawData =
          await parser.pickAndParseFile(type);

      if (rawData.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("No transactions found or cancelled.")),
          );
        }
        return;
      }

      // 4. Save parsed data to Firestore
      final firestoreService = context.read<FirestoreService>();
      int count = 0;

      for (var data in rawData) {
        // Safe data conversion
        double amount = (data['amount'] is num) 
            ? (data['amount'] as num).toDouble() 
            : 0.0;
        
        String title = data['title'] ?? 'Unknown';
        String dateStr = data['date'] ?? '';
        bool isIncome = data['type'] == 'Income'; // Simple check

        // Attempt to parse date (handle dd/MM/yyyy vs yyyy-MM-dd)
        DateTime date;
        try {
          if (dateStr.contains('/')) {
             List<String> parts = dateStr.split('/');
             if (parts.length == 3) {
                // assume dd/MM/yyyy
                date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
             } else {
               date = DateTime.now();
             }
          } else {
             date = DateTime.tryParse(dateStr) ?? DateTime.now();
          }
        } catch (e) {
          date = DateTime.now();
        }

        // Create Transaction Object
        final tx = TransactionModel(
          title:title,
          amount: amount,
          category: 'Imported', // You can change this later to be smarter
          note: title,
          date: date,
          isIncome: isIncome,
        );

        // Add to Database
        await firestoreService.addTransaction(tx);
        count++;
      }

      // 5. Success Message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully imported $count transactions!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error importing: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- UI: Format Selection Dialog ---
  void _showImportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select File Format",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              _buildImportOption(
                ctx, 
                icon: Icons.table_chart, 
                label: "Excel (XLSX)", 
                color: Colors.green,
                onTap: () => _handleImport(context, FileTypeOption.excel),
              ),
              
              _buildImportOption(
                ctx, 
                icon: Icons.description, 
                label: "CSV File", 
                color: Colors.blue,
                onTap: () => _handleImport(context, FileTypeOption.csv),
              ),
              
              _buildImportOption(
                ctx, 
                icon: Icons.picture_as_pdf, 
                label: "PDF Statement", 
                color: Colors.red,
                onTap: () => _handleImport(context, FileTypeOption.pdf),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImportOption(BuildContext context, {
    required IconData icon, 
    required String label, 
    required Color color,
    required VoidCallback onTap
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
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

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  @override
  Widget build(BuildContext context) {
    final transactionBloc = context.read<TransactionBloc>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF3F4F6),
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading || state is TransactionInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TransactionError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is TransactionLoaded) {
            final transactions = state.transactions;
            final summary = _calculateSummary(transactions);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: _buildHeader(),
                  ),
                ),

                // SUMMARY CARD
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildSummaryCard(context, summary),
                  ),
                ),

                // QUICK ACTIONS
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Quick Actions",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                context,
                                label: "Add Manual",
                                icon: Icons.add_circle_outline,
                                color: Colors.indigo,
                                onTap: () => _openAddTransactionScreen(context),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildActionButton(
                                context,
                                label: "Upload Statement", 
                                icon: Icons.file_upload_outlined,
                                color: Colors.orange.shade800,
                                // --- UPDATED: Calls the new dialog ---
                                onTap: () => _showImportOptions(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
                    child: Text(
                      'Recent Transactions',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                // TRANSACTION LIST
                transactions.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No transactions recorded yet.',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, index) {
                            final tx = transactions[index];

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TransactionTile(
                                tx: tx,
                                onEdit: () => _openAddTransactionScreen(
                                  context,
                                  txToEdit: tx,
                                ),
                                onDelete: () {
                                  transactionBloc
                                      .add(DeleteTransactionEvent(tx.id!));
                                },
                              ),
                            );
                          },
                          childCount: transactions.length,
                        ),
                      ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            );
          }

          return const Center(child: Text('Waiting for data...'));
        },
      ),
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Welcome Back,", style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text("Ahsen Durmaz", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF6C63FF), width: 2),
          ),
          child: const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=32"),
          ),
        )
      ],
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, double> summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B4DBC), Color(0xFF6C63FF)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 15)),
              Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₺${summary['balance']!.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Income',
                  amount: summary['income']!,
                  iconColor: const Color(0xFF4ADE80),
                  bgColor: const Color(0xFF4ADE80).withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Expense',
                  amount: summary['expense']!,
                  iconColor: const Color(0xFFF87171),
                  bgColor: const Color(0xFFF87171).withOpacity(0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required double amount,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
              Text(
                '₺${amount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
