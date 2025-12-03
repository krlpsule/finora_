// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'charts.dart';
import 'history.dart'; // Boş bir dosya oluşturun
import 'ai_assistant.dart'; // Boş bir dosya oluşturun

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ChartsPage(),
    const HistoryPage(), // Boş oluşturun
    const AIAssistantPage(), // Boş oluşturun
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar ve FloatingActionButton, alt sayfalara taşınacaksa buradan kaldırılabilir.
      // Şimdilik sadece sayfa içeriğini döndürüyoruz.
      body: _pages[_selectedIndex],
      
      // Alt Gezinti Çubuğu
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
        type: BottomNavigationBarType.fixed, // 4-5 item için sabit tip daha iyidir
      ),
    );
  }
}

// HistoryPage ve AIAssistantPage için basit placeholder'lar (Eğer henüz kodlamadıysanız)
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(appBar: AppBar(title: Text('Transaction History')), body: Center(child: Text('History List Coming Soon')));
  }
}

// AIAssistantPage için basit placeholder
class AIAssistantPage extends StatelessWidget {
  const AIAssistantPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(appBar: AppBar(title: Text('AI Assistant')), body: Center(child: Text('AI Chat Coming Soon')));
  }
}