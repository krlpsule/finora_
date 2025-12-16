// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'charts.dart';
import 'history.dart'; // Now using the real history file
import 'ai_assistant.dart';
import 'add_transaction.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Use the real classes here
  final List<Widget> _pages = const [
    DashboardPage(),
    ChartsPage(),
    HistoryScreen(), // Changed from HistoryPage to HistoryScreen (match class name in history.dart)
    AIAssistantPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openAddTransactionScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const AddTransactionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = [
      'Finora',
      'Analytics',
      'History',
      'Assistant'
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Using a simpler AppBar or no AppBar for some screens can look cleaner
      // but keeping it for consistency
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _pages[_selectedIndex],
      ),

      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF5B4DBC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openAddTransactionScreen,
          elevation: 0,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(Icons.add, size: 30, color: Colors.white),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: _onItemTapped,
          showSelectedLabels: false, // Modern cleaner look
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), 
              activeIcon: Icon(Icons.dashboard),
              label: "Home"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart), 
              label: "Charts"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history), 
              activeIcon: Icon(Icons.history_edu), // Fun visual change
              label: "History"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined), 
              activeIcon: Icon(Icons.auto_awesome),
              label: "AI"
            ),
          ],
        ),
      ),
    );
  }
}
