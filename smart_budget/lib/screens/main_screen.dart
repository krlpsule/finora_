// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/transaction/transaction_bloc.dart';
import '../features/transaction/transaction_state.dart';
import '../models/transaction_model.dart'; // For type casting
import 'dashboard.dart';
import 'charts.dart';
import 'ai_assistant.dart';
import 'add_transaction.dart';
import '/widgets/import_statement_widget.dart'; // The widget for file upload

// -----------------------------------------------------------------------------------

// HistoryPage is now a StatelessWidget that listens to TransactionBloc for data
class HistoryPage extends StatelessWidget {
  // CRITICAL FIX: Removed the unnecessary local transactions list.
  // Data will be streamed via BlocBuilder.
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the TransactionBloc state changes
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TransactionLoaded) {
          final transactions = state.transactions;

          if (transactions.isEmpty) {
            // UI for empty state
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text(
                      'There is no transaction history yet.\nYou can upload a statement from the top right.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Display the transaction list using data from Firebase via BLoC
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index]; // tx is now a TransactionModel
              final isExpense = !tx.isIncome; // Expense if not Income

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  // Icon for Income/Expense
                  leading: CircleAvatar(
                    backgroundColor:
                        isExpense ? Colors.red[50] : Colors.green[50],
                    child: Icon(
                      isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isExpense ? Colors.red : Colors.green,
                      size: 20,
                    ),
                  ),
                  // Use the 'title' property from the TransactionModel
                  title: Text(tx.title),
                  // Display only the date part
                  subtitle: Text(tx.date.toString().split(' ')[0]),
                  trailing: Text(
                    // Format amount to 2 decimal places
                    "${tx.amount.toStringAsFixed(2)} TL",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  // TODO: Implement onTap for editing transaction (e.g., using AddTransactionPage)
                ),
              );
            },
          );
        }

        // Default state (Error or Initial)
        return const Center(child: Text('Start adding transactions!'));
      },
    );
  }
}

// -----------------------------------------------------------------------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 🛑 REMOVED: Local list _importedTransactions and the callback method _handleLoadedTransactions
  // are no longer needed, as data flows directly to Firebase via BLoC.

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openAddTransactionScreen() {
    // Navigate to the screen for adding/editing transactions
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const AddTransactionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pages list, dynamically accessing the TransactionBloc for the History tab
    final List<Widget> pages = [
      const DashboardPage(),
      const ChartsPage(),
      // CRITICAL FIX: Wrap HistoryPage with BlocProvider.value
      // to ensure it can access the existing TransactionBloc from the main tree.
      BlocProvider.value(
        value: context.read<TransactionBloc>(),
        child: const HistoryPage(),
      ),
      const AIAssistantPage(),
    ];

    final List<String> titles = [
      'Finora Dashboard',
      'Financial Charts',
      'Transaction History',
      'AI Assistant'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        elevation: 0,
        actions: [
          // CRITICAL FIX: Removed the conflicting 'onDataLoaded' parameter.
          // ImportStatementWidget now sends data directly to BLoC.
          const ImportStatementWidget(),
          const SizedBox(width: 10),

          // TODO: Add Logout Button here (if not already done)
        ],
      ),
      body: pages[_selectedIndex],

      // Floating Action Button for adding new transaction
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransactionScreen,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Charts'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'AI'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
