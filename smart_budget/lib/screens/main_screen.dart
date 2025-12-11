// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'charts.dart';
import 'ai_assistant.dart';
import 'add_transaction.dart'; 
import 'finora_/smart_budget/lib/widgets/import_statement_widget.dart'; 

class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const HistoryPage({super.key, this.transactions = const []});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            SizedBox(height: 10),
            Text('Henüz işlem geçmişi yok.\nSağ üstten ekstre yükleyebilirsin.', 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isExpense = tx['type'] == 'Gider';
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isExpense ? Colors.red[50] : Colors.green[50],
              child: Icon(
                isExpense ? Colors.arrow_downward : Colors.arrow_upward,
                color: isExpense ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            title: Text(tx['title'] ?? 'Bilinmiyor'),
            subtitle: Text(tx['date'].toString()),
            trailing: Text(
              "${tx['amount']} TL",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
          ),
        );
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

  List<Map<String, dynamic>> _importedTransactions = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleLoadedTransactions(List<Map<String, dynamic>> newTransactions) {
    setState(() {
      // Yeni gelenleri mevcut listenin başına ekle
      _importedTransactions.insertAll(0, newTransactions);
      
      _selectedIndex = 2; 
    });
  }

  void _openAddTransactionScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const AddTransactionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const DashboardPage(),
      const ChartsPage(),
      HistoryPage(transactions: _importedTransactions),
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
          ImportStatementWidget(
            onDataLoaded: _handleLoadedTransactions,
          ),
          SizedBox(width: 10), 
        ],
      ),

      body: pages[_selectedIndex],

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransactionScreen,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

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
