// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'charts.dart';
import 'history.dart';
import 'ai_assistant.dart';
import 'add_transaction.dart'; // İşlem ekleme ekranı

// --- Placeholder/Diğer Sayfaların Const Tanımlamaları (Çalışma Garantisi için) ---
// Not: Bu sınıflar kendi dosyalarından (history.dart, ai_assistant.dart) geliyorsa,
// buraya sadece import yeterlidir.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    // MainScreen'de AppBar yönetildiği için burada sadece Center kullanıyoruz.
    return const Center(child: Text('Transaction History Coming Soon'));
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

  // PRD'deki tüm ana ekranları içeren liste
  final List<Widget> _pages = const [
    DashboardPage(),
    ChartsPage(),
    HistoryPage(),
    AIAssistantPage(),
  ];

  // Sekme değişimini yönetir
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // İşlem Ekleme Ekranını açma metodu
  void _openAddTransactionScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const AddTransactionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Seçili sekmeye göre başlık listesi
    final List<String> titles = [
      'Finora Dashboard',
      'Financial Charts',
      'Transaction History',
      'AI Assistant'
    ];

    return Scaffold(
      // PRD 7.1'e uygun tek AppBar, sekmeler arasında başlığı değiştirir
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        elevation: 0,
      ),

      // Gösterilen sayfa
      body: _pages[_selectedIndex],

      // Floating Action Button (İşlem Ekleme)
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransactionScreen,
        child: const Icon(Icons.add),
      ),
      // FAB'ı Bottom Navigasyonun ortasına yerleştirme (UX gereksinimi)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Alt Gezinti Çubuğu (BottomNavigationBar)
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Charts'),
          // FAB için boşluk bırakılır
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'AI'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Tüm öğelerin görünmesini sağlar
      ),
    );
  }
}
